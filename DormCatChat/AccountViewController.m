//
//  ThirdViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 1/18/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "AccountViewController.h"
#import "Macro.h"
#import "ImageProcessor.h"
#import "AccountImageCell.h"
#import "LoginViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "DCTabBarController.h"
#import "CleanerAccountViewController.h"
#import "EditViewController.h"
#import "TAlertView.h"
#import "Utility.h"

typedef enum{
    CleanerLoggedIn,
    UserLoggedIn,
    LoggedOut
} UserStatus;

static NSString *const AccountCellIdentifier = @"AccountCell";
static NSString *const AccountImageCellIdentifier = @"AccountImageCell";

@implementation AccountViewController{
    //ImageProcessor *imageProcessor;
    NSArray *titleArray;
    NSMutableArray *userInfo;
    NSCache *_imageCache;
}

-(void)viewDidLoad{
    titleArray = [[NSArray alloc] initWithObjects:NAME,EMAIL,nil];
    userInfo = [[NSMutableArray alloc] init];
    
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _imageCache = appDelegate.globalImageCache;

    self.view.backgroundColor = UIColorFromRGB(FLAT_GRAY);
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    UINib *cellNib = [UINib nibWithNibName:AccountImageCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:AccountImageCellIdentifier];
    [self.view addSubview:self.tableView];
    [self addFooter:LoggedOut];
    [self configureAlertViewColors];
    
    NSLog(@"self.view width %f",self.view.frame.size.width);
    NSLog(@"tableView width %f",self.tableView.frame.size.width);
    
    self.parentTabBarController.navigationController.navigationBar.topItem.title = @"Account";
}

-(void)viewDidAppear:(BOOL)animated{
    self.parentTabBarController.navigationItem.leftBarButtonItem = nil;
    self.parentTabBarController.navigationItem.rightBarButtonItem = nil;
    [Utility addTitleLabelToNavigationItem:self.parentTabBarController.navigationController.navigationBar.topItem withText:@"Account"];
    
    [self updateLoginUI];
}

-(void)configureAlertViewColors
{
    TAlertView *appearance = [TAlertView appearance];
    appearance.alertBackgroundColor     = [UIColor whiteColor];
    appearance.titleFont                = [UIFont fontWithName:AVENIR_LIGHT size:14];
    appearance.messageColor             = [UIColor grayColor];
    appearance.messageFont              = [UIFont fontWithName:AVENIR_LIGHT size:16];
    appearance.buttonsTextColor         = [UIColor grayColor];
    appearance.buttonsFont              = [UIFont fontWithName:AVENIR_LIGHT size:16];
    appearance.separatorsLinesColor     = UIColorFromRGB(FLAT_GREEN);
    appearance.tapToCloseFont           = [UIFont fontWithName:AVENIR_LIGHT size:10];
    appearance.tapToCloseColor          = [UIColor grayColor];
    appearance.tapToCloseText           = @"Touch to close";
    [appearance setTitleColor:[UIColor orangeColor] forAlertViewStyle:TAlertViewStyleError];
    [appearance setDefaultTitle:@"Error" forAlertViewStyle:TAlertViewStyleError];
    [appearance setTitleColor:[UIColor whiteColor] forAlertViewStyle:TAlertViewStyleNeutral];
}

-(void)updateLoginUI
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ((self.userData = [defaults objectForKey:AUTH_DATA]) != nil) {
        // if a cached session was found
        self.cleanerData = [defaults objectForKey:CLEANER_INFO];
        if([userInfo count] == 0){
            if([self.userData valueForKey:@"displayName"] != nil){
                [userInfo addObject:self.userData[@"displayName"]];
            }
            
            if(self.userData[@"email"] != nil){
                [userInfo addObject:self.userData[@"email"]];
            }
        }
        [self.tableView reloadData];
        
        NSLog(@"cleaner info %@", self.cleanerData);
        if(self.cleanerData != nil){
            [self addQuitItem];
            [self addFooter:CleanerLoggedIn];
        }else{
            self.parentTabBarController.navigationItem.leftBarButtonItem = nil;
            [self addFooter:UserLoggedIn];
        }
        
        [self addLogOutBtn];
    }else{
        self.userData = nil;
        [userInfo removeAllObjects];
        [self.tableView reloadData];
        self.parentTabBarController.navigationItem.rightBarButtonItem = nil;
        self.parentTabBarController.navigationItem.leftBarButtonItem = nil;
        [self addFooter:LoggedOut];
    }
}

-(void)addFooter:(UserStatus)status
{
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 100)];
    footer.backgroundColor = [UIColor clearColor];
    UIButton * footerBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    footerBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [footerBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    footerBtn.backgroundColor = UIColorFromRGB(FLAT_GREEN);
    footerBtn.layer.cornerRadius = 10;
    footerBtn.layer.masksToBounds = YES;
    footerBtn.titleLabel.font = [UIFont fontWithName:AVENIR_LIGHT size:15];
    
    switch (status) {
        case LoggedOut:
            [footerBtn addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
            [footerBtn setTitle:@"Login" forState:UIControlStateNormal];
            break;
        case CleanerLoggedIn:
            [footerBtn addTarget:self action:@selector(showCleanerInfo) forControlEvents:UIControlEventTouchDown];
            [footerBtn setTitle:@"Cleaning Account" forState:UIControlStateNormal];
            //footerBtn.backgroundColor = UIColorFromRGB(FLAT_RED);
            [self addLogOutBtn];
            break;
        case UserLoggedIn:
            [footerBtn addTarget:self action:@selector(becomeCleaner) forControlEvents:UIControlEventTouchDown];
            [footerBtn setTitle:@"Become A Cleaner" forState:UIControlStateNormal];
            [self addLogOutBtn];
            break;
        default:
            break;
    }
    
    [footerBtn.titleLabel setFont:[UIFont fontWithName:AVENIR_LIGHT size:20]];
    [footer addSubview:footerBtn];
    NSLayoutConstraint *heightContraint = [NSLayoutConstraint constraintWithItem:footerBtn
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:50];
    [footerBtn addConstraint:heightContraint];
    
    NSLayoutConstraint *widthContraint = [NSLayoutConstraint constraintWithItem:footerBtn
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:200];
    [footerBtn addConstraint:widthContraint];
    NSLayoutConstraint *yContraint = [NSLayoutConstraint constraintWithItem:footerBtn
                                                                       attribute:NSLayoutAttributeCenterY
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:footer
                                                                       attribute:NSLayoutAttributeCenterY
                                                                      multiplier:1.0
                                                                        constant:0];
    
    [footer addConstraint:yContraint];
    
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:footerBtn
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:footer
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1.0
                                  constant:0];
    
    [footer addConstraint:xConstraint];
    
    self.tableView.tableFooterView = footer;
}

-(void)showCleanerInfo
{
    CleanerAccountViewController *cleanerAccountViewController = [CleanerAccountViewController new];
    
    NSArray *keys = [NSArray arrayWithObjects:@"phone",@"school",@"price",@"supplies",@"service",nil];
    NSMutableArray *detailArray = [NSMutableArray new];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *cleanerData = [defaults objectForKey:CLEANER_INFO];
    
    for(NSString *key in keys){
        if(cleanerData[key])
            [detailArray addObject:cleanerData[key]];
        else
            [detailArray addObject:@"Nothing"];
    }
    
    cleanerAccountViewController.displayDetailArray = detailArray;
    [self.parentTabBarController.navigationController pushViewController:cleanerAccountViewController animated:YES];
}

-(void)showQuitDialog
{
    NSArray * buttons = @[@"Yes", @"No"];
    TAlertView *alert = [[TAlertView alloc] initWithTitle:nil
                                                  message:@"Do you want to quit as a cleaner ?"
                                                  buttons:buttons
                                              andCallBack:^(TAlertView *alertView, NSInteger buttonIndex) {
                                                  if(buttonIndex == 0) {
                                                      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                      NSString * uid = [defaults objectForKey:UID];
                                                      Firebase *firebase = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
                                                      Firebase *cleanerInfoBase = [firebase childByAppendingPath:[NSString stringWithFormat:@"cleaners/%@",uid]];
                                                      [cleanerInfoBase setValue:nil];
                                                      [defaults removeObjectForKey:CLEANER_INFO];
                                                      [self updateLoginUI];
                                                  }
                                              }];
    alert.buttonsAlign = TAlertViewButtonsAlignHorizontal;
    [alert showAsMessage];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
   // NSLog(@"Button Index = %d",buttonIndex);
    if (buttonIndex == 1)
    {
        // allow the cleaner to quit
       
    }
}

-(void)login
{
    LoginViewController *logInViewController = [LoginViewController new];
    [self presentViewController:logInViewController animated:YES completion:nil];
}

-(void)addLogOutBtn{
    UIBarButtonItem *logOutItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"logout.png"] style:UIBarButtonItemStylePlain target:self action:@selector(logout)];
    logOutItem.tintColor = [UIColor whiteColor];
    self.parentTabBarController.navigationItem.rightBarButtonItem = logOutItem;
}

-(void)addQuitItem
{
    UIBarButtonItem *quitItem = [[UIBarButtonItem alloc] initWithTitle:@"Quit" style:UIBarButtonItemStylePlain target:self action:@selector(showQuitDialog)];
    quitItem.tintColor = [UIColor whiteColor];
    self.parentTabBarController.navigationItem.leftBarButtonItem = quitItem;
}

-(void)logout
{
    NSArray * buttons = @[@"Log Out", @"Cancel"];
    TAlertView *alert = [[TAlertView alloc] initWithTitle:nil
                                                  message:@"Do you want to log out ?"
                                                  buttons:buttons
                                              andCallBack:^(TAlertView *alertView, NSInteger buttonIndex) {
                                                  switch (buttonIndex) {
                                                      case 0:
                                                          [FBSession.activeSession close];
                                                          [FBSession setActiveSession:nil];
                                                          
                                                          NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                                                          [defaults removeObjectForKey:AUTH_DATA];
                                                          [defaults removeObjectForKey:CLEANER_INFO];
                                                          
                                                          AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                                          [appDelegate.chatViewController loadData];// this wipe out data in chatViewController;
                                                          [appDelegate.chatViewController.tableView reloadData];
                                                          
                                                          [self updateLoginUI];
                                                          break;
                                                  }
                                              }];
    alert.buttonsAlign = TAlertViewButtonsAlignHorizontal;
    [alert showAsMessage];
}

-(void)becomeCleaner
{
    CleanerAccountViewController *becomeCleanerViewController = [[CleanerAccountViewController alloc] init];
    becomeCleanerViewController.delegate = self;
    [self.parentTabBarController.navigationController pushViewController:becomeCleanerViewController animated:YES];
}

#pragma mark CleanerAccountViewControllerDelegate methods

-(void)updateUIAfterSubmission{
    //NSLog(@"calling update UI");
    [self updateLoginUI];
}

#pragma mark table view methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 0 && indexPath.section == 0){
        AccountImageCell *cell = (AccountImageCell *)[tableView dequeueReusableCellWithIdentifier:AccountImageCellIdentifier];
        NSString * imageStringURLString = self.userData[@"cachedUserProfile"][@"picture"][@"data"][@"url"];
        if([imageStringURLString length]){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *img;
                if([_imageCache objectForKey:imageStringURLString] == nil){
                    img = [ImageProcessor imageFromURL:imageStringURLString];
                    if(img != nil){
                        [_imageCache setObject:img forKey:imageStringURLString];
                    }else{
                        img = [UIImage imageNamed:@"missingAvatar.png"];
                    }
                }else{
                    img = [_imageCache objectForKey:imageStringURLString];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell.customImageView setImage:[ImageProcessor roundCorneredImage:img radius:8]];
                });
            });
        }else{
            [cell.customImageView setImage:[ImageProcessor roundCorneredImage:[UIImage imageNamed:@"missingAvatar.png"] radius:16]];
        }
        
        [cell.imageCellTextLabel setText:@"Profile Image"];
        [cell.imageCellTextLabel setFont:[UIFont fontWithName:AVENIR_LIGHT size:16]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }else{
        UITableViewCell * cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:AccountCellIdentifier];
        if(!cell){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:AccountCellIdentifier];
        }
        
        
        [cell.textLabel setText:[titleArray objectAtIndex:indexPath.row]];
        [cell.textLabel setFont:[UIFont fontWithName:AVENIR_LIGHT size:16]];
        if([userInfo count] > indexPath.row){
            [cell.detailTextLabel setText:userInfo[indexPath.row]];
        }else{
            [cell.detailTextLabel setText:@"..."];
        }
        [cell.detailTextLabel setFont:[UIFont fontWithName:AVENIR_LIGHT size:16]];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0 && indexPath.section == 0){
        return 70;
    }else{
        return 45;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0){
        return 1;
    }else if(section == 1){
        return [titleArray count];
    }else{
        return 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark EditViewController delegate methods

-(void)updateNewValueAtRow:(NSIndexPath *)indexPath withValue:(NSString *)value
{
    [[self.tableView cellForRowAtIndexPath:indexPath].detailTextLabel setText:value];
}


@end
