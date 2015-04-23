//
//  FirstViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 1/18/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "ChatViewController.h"
#import "ChatViewController.h"
#import "DCTabBarController.h"
#import "DCTabBarItem.h"
#import "CleanerChatCell.h"
#import "ChatViewController.h"
#import "AppDelegate.h"
#import "ImageProcessor.h"
#import "Macro.h"
#import <Firebase/Firebase.h>
#import <FacebookSDK/FacebookSDK.h>
#import "LoginViewController.h"
#import "Utility.h"
#import "MessageViewController.h"

static NSString *const CleanerCellIdentifier = @"CleanerChatCell";

@implementation ChatViewController{
    NSMutableSet *uidSet;
    BOOL loginState;
    BOOL loadBatch;
    NSCache *_imageCache;
    NSCache *_chatMessageViewControllerCache;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = nil;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    loadBatch = YES;
    uidSet = [[NSMutableSet alloc] init];
    loginState = NO;
    self.chatPeople = [[NSMutableArray alloc] init];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _chatMessageViewControllerCache = appDelegate.chatBubbleViewControllerCache;
    _imageCache = appDelegate.globalImageCache;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    UINib *cellNib = [UINib nibWithNibName:CleanerCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:CleanerCellIdentifier];
    self.tableView.rowHeight = 60;
    self.tableView.backgroundColor = UIColorFromRGB(CHAT_BACKGROUND);
    if (self.dc_tabBarController.tabBar.translucent) {
        UIEdgeInsets insets = UIEdgeInsetsMake(0,
                                               0,
                                               CGRectGetHeight(self.dc_tabBarController.tabBar.frame),
                                               0);
        self.tableView.contentInset = insets;
        self.tableView.scrollIndicatorInsets = insets;
    }
    [self.view addSubview:self.tableView];
}

-(void)loadData{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:AUTH_DATA]){
            [uidSet removeAllObjects];
            [self.chatPeople removeAllObjects];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *uid = [defaults objectForKey:UID];
            Firebase *fireBase = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
            Firebase *cleanerChatsBase = [fireBase childByAppendingPath:[NSString stringWithFormat:@"%@/%@",CHATS_LIST,uid]];
            
            [cleanerChatsBase observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                if(snapshot.exists){
                    for(id key in snapshot.value){
                        if(![uidSet containsObject:key]){
                            [uidSet addObject:key];
                            NSMutableDictionary *mutableChatInfo = [snapshot.value[key] mutableCopy];
                            [self.chatPeople addObject:mutableChatInfo];
                        };
                    }
                   [self.tableView reloadData];
                }
            }];
    }else{
        [uidSet removeAllObjects];
        [self.chatPeople removeAllObjects];
        [self.tableView reloadData];
    }
    });
}

-(void)viewDidAppear:(BOOL)animated
{
    [Utility addTitleLabelToNavigationItem:self.parentTabBarController.navigationController.navigationBar.topItem withText:@"Messages"];
    self.parentTabBarController.navigationItem.leftBarButtonItem = nil;
    self.parentTabBarController.navigationItem.rightBarButtonItem = nil;
    [self loadData];
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - Methods

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [[cell textLabel] setText:[NSString stringWithFormat:@"%@ Controller Cell %ld", self.title, (long)indexPath.row]];
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *chatInfo = [self.chatPeople objectAtIndex:indexPath.row];
    NSString *userProfileURL = chatInfo[@"profile_url"];
    CleanerChatCell *cell = (CleanerChatCell *)[tableView dequeueReusableCellWithIdentifier:CleanerCellIdentifier];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *profileImage;
        if([_imageCache objectForKey:userProfileURL] == nil){
            profileImage = [ImageProcessor imageFromURL:userProfileURL];
            if(profileImage != nil){
                [_imageCache setObject:profileImage forKey:userProfileURL];
            }else{
                profileImage = [UIImage imageNamed:@"missingAvatar.png"];
            }
        }else{
            profileImage = [_imageCache objectForKey:userProfileURL];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.profileImage setImage:[ImageProcessor roundCorneredImage:profileImage radius:8]];
        });
    });
    
    [cell.lastMessage setText:chatInfo[@"message"]];
    
    if([chatInfo[@"status"] isEqualToString:@"unread"]){
        cell.lastMessage.textColor=[UIColor blackColor];
    }else{
        cell.lastMessage.textColor=[UIColor grayColor];
    }
    
    [cell.userName setText:chatInfo[@"name"]];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:DATE_FORMAT_STRING];
    NSDate *lastChatDate = [dateFormatter dateFromString:chatInfo[@"date"]];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [cell.date setText:[dateFormatter stringFromDate:lastChatDate]];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.chatPeople count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString * uid = [self.chatPeople objectAtIndex:indexPath.row][@"uid"];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:AUTH_DATA]){
        if(uid != nil){
            MessageViewController *chatMessageViewController;
            if([_chatMessageViewControllerCache objectForKey:uid] != nil){
                chatMessageViewController = [_chatMessageViewControllerCache objectForKey:uid];
            }else{
                chatMessageViewController = [MessageViewController new];
                [_chatMessageViewControllerCache setObject:chatMessageViewController forKey:uid];
            }
            chatMessageViewController.otherId = [self.chatPeople objectAtIndex:indexPath.row][@"uid"];
            chatMessageViewController.otherDisplayName = [self.chatPeople objectAtIndex:indexPath.row][@"name"];
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            CleanerChatCell *cell = (CleanerChatCell *)[tableView cellForRowAtIndexPath:indexPath];
            cell.lastMessage.textColor = [UIColor grayColor];
            // check for cached chat bubble view controllers
            [appDelegate.navigationController pushViewController:chatMessageViewController animated:YES];
        }
    }else{
        LoginViewController *logInViewController = [LoginViewController new];
        [self presentViewController:logInViewController animated:YES completion:nil];
    }
}

- (void)updateChatLastMessage:(NSDictionary *)lastMessageDict WithID:(NSString *)uid {
    
}

- (void)updateChatsWithNotification:(NSDictionary *)notification {
    
}


@end

