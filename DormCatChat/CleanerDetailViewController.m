//
//  CleanerDetailViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 1/24/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "CleanerDetailViewController.h"
#import "ImageProcessor.h"
#import "CleanerReviewCell.h"
#import "Macro.h"
#import <FacebookSDK/FacebookSDK.h>
#import "LoginViewController.h"
#import "EditReviewController.h"
#import "AppDelegate.h"
#import <Firebase/Firebase.h>
#import "Utility.h"
#import "MessageViewController.h"

static NSString *const CleanerCellIdentifier = @"CleanerReviewCell";

@interface CleanerDetailViewController ()

@end

@implementation CleanerDetailViewController{
    UIImage *img;
    void(^loginCompletionBlock)(void);
    NSMutableArray *reviews;
    NSCache *_chatMessageViewControllerCache;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
   // imageProcessor = [ImageProcessor new];
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _chatMessageViewControllerCache = appDelegate.chatBubbleViewControllerCache;
    
    self.view.backgroundColor = [UIColor whiteColor];
    // create Table View
    CGFloat tableHeight = [[UIScreen mainScreen] bounds].size.height - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.navigationController.view.frame.size.width, tableHeight) style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    self.tableView.rowHeight = 120;
    UINib *cellNib = [UINib nibWithNibName:CleanerCellIdentifier bundle:nil];
    CGRect frame = self.tableView.frame;
    self.tableView.frame = frame;
    [self.tableView registerNib:cellNib forCellReuseIdentifier:CleanerCellIdentifier];
    [self setUpHeaderView];
    reviews = [[NSMutableArray alloc] init];
    [self loadReviews];
}

-(void)loadReviews
{
    Firebase *reviewsBase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/cleaners/%@/reviews",FIREBASE_ROOT_URL,self.cleanerInfo[@"uid"]]];
    
    [reviewsBase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"reviews snapshot %@",snapshot.value);
        [reviews addObject:snapshot.value];
    }];
    
    [reviewsBase observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        [self.tableView reloadData];
    }];
    
}

-(void)setUpHeaderView{
    
    self.container = [UIView new];
    CGRect frame = CGRectMake(0,0,280,200);
    [self.container setFrame:frame];
    
    // create userimage
    NSString *imageStringURLString = self.cleanerInfo[@"profile_url"];
    img = [ImageProcessor imageFromURL:imageStringURLString];
    if(!img)
        img = [UIImage imageNamed:@"missingAvatar.png"];
    
    self.userimage = [UIImageView new];
    self.userimage.translatesAutoresizingMaskIntoConstraints = NO;
    [self.userimage setImage:[ImageProcessor roundCorneredImage:img radius:8]];
    [self.container addSubview:self.userimage];
    
    //set up username
    self.username = [UILabel new];
    self.username.translatesAutoresizingMaskIntoConstraints = NO;
    [self.username setText:self.cleanerInfo[@"name"]];
    [self.username setFont:[UIFont fontWithName:AVENIR_LIGHT size:16]];
    [self.container addSubview:self.username];
    
    //set up userinfo
    NSString * distance = [Utility friendlyDistance:self.cleanerInfo[@"distance"]];
    
    self.userinfo = [UILabel new];
    self.userinfo.translatesAutoresizingMaskIntoConstraints = NO;
    [self.userinfo setText:[NSString stringWithFormat:@"Goes to %@, %@ from you.",self.cleanerInfo[@"school"],distance]];
    self.userinfo.numberOfLines = 1;
    [self.userinfo setFont:[UIFont fontWithName:AVENIR_LIGHT size:12]];
    [self.userinfo setTextColor:[UIColor grayColor]];
    [self.container addSubview:self.userinfo];
    
    //set up cleaner's service description
    self.service = [UITextView new];
    self.service.translatesAutoresizingMaskIntoConstraints = NO;
    [self.service setText:self.cleanerInfo[@"service"]];
    [self.service setFont:[UIFont fontWithName:AVENIR_LIGHT size:15]];
    [self.service setTextColor:[UIColor grayColor]];
    self.service.editable = NO;
    self.service.backgroundColor = [UIColor clearColor];
    [self.container addSubview:self.service];
    
    self.chatButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.chatButton addTarget:self action:@selector(startChat) forControlEvents:UIControlEventTouchDown];
    [self.chatButton setTitle:@"Chat" forState:UIControlStateNormal];
    [self styleButton:self.chatButton];
    
    self.callButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.callButton addTarget:self action:@selector(startCall) forControlEvents:UIControlEventTouchUpInside];
    [self.callButton setTitle:@"Call" forState:UIControlStateNormal];
    [self styleButton:self.callButton];
    
    self.reviewButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.reviewButton addTarget:self action:@selector(addReview) forControlEvents:UIControlEventTouchUpInside];
    [self.reviewButton setTitle:@"Add Review" forState:UIControlStateNormal];
    [self styleButton:self.reviewButton];
    
    self.container.backgroundColor = UIColorFromRGB(FLAT_GRAY);
    [self setUpConstraints];
    self.tableView.tableHeaderView = self.container;
    self.tableView.tableHeaderView.frame = frame;
}

-(void)styleButton:(UIButton *)btn
{
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = UIColorFromRGB(FLAT_GREEN);
    btn.layer.cornerRadius = 10;
    btn.layer.masksToBounds = YES;
    btn.titleLabel.font = [UIFont fontWithName:AVENIR_LIGHT size:15];
    [self.container addSubview:btn];
}


-(void)setUpConstraints
{
    NSDictionary *viewsDictionary = @{@"userimage":self.userimage,
                                      @"username":self.username,
                                      @"chatbutton":self.chatButton,
                                      @"reviewbutton":self.reviewButton,
                                      @"callbutton":self.callButton,
                                      @"service":self.service,
                                      @"userinfo":self.userinfo};
    
    NSDictionary *metrics = @{@"userimageWidth": @50,
                              @"userimageHeight": @50,
                              @"usernameWidth": @280,
                              @"usernameHeight": @20,
                              @"userinfoWidth": @280,
                              @"userinfoHeight":@20,
                              @"viewSpacing":@10,
                              @"chatbuttonWidth":@50,
                              @"callbuttonWidth":@50,
                              @"reviewbuttonWidth":@100,
                              @"buttonHeight":@30,
                              @"bottomMargin":@20,
                              @"leftMargin":@10,
                              @"topMargin":@20
                              };
    
    // constraints for userimage
    NSArray *userimageConstraintWidth = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[userimage(userimageWidth)]"
                                                                           options:0
                                                                           metrics:metrics
                                                                             views:viewsDictionary];
    
    NSArray *userimageConstraintHeight = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[userimage(userimageHeight)]"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:viewsDictionary];
    
    [self.userimage addConstraints:userimageConstraintHeight];
    [self.userimage addConstraints:userimageConstraintWidth];
    
    NSArray *image_container_pos_h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leftMargin-[userimage]"
                                                                               options:0
                                                                               metrics:metrics
                                                                                 views:viewsDictionary];
    
    NSArray *image_container_pos_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topMargin-[userimage]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:viewsDictionary];
    [self.container addConstraints:image_container_pos_h];
    [self.container addConstraints:image_container_pos_v];
    
    //constraints for username
    NSArray *usernameConstraintWidth = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[username(usernameWidth)]"
                                                                                options:0
                                                                                metrics:metrics
                                                                                  views:viewsDictionary];
    
    NSArray *usernameConstraintHeight = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[username(usernameHeight)]"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:viewsDictionary];
    
    [self.username addConstraints:usernameConstraintHeight];
    [self.username addConstraints:usernameConstraintWidth];
    
    //constraints for userinfo
    NSArray *userinfoConstraintWidth = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[userinfo(userinfoWidth)]"
                                                                               options:0
                                                                               metrics:metrics
                                                                                 views:viewsDictionary];
    
    NSArray *userinfoConstraintHeight = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[userinfo(userinfoHeight)]"
                                                                                options:0
                                                                                metrics:metrics
                                                                                  views:viewsDictionary];
    
    [self.userinfo addConstraints:userinfoConstraintHeight];
    [self.userinfo addConstraints:userinfoConstraintWidth];
    
    
    //constraints for chatbutton
    NSArray *chatbuttonConstraintWidth = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[chatbutton(chatbuttonWidth)]"
                                                                               options:0
                                                                               metrics:metrics
                                                                                 views:viewsDictionary];
    
    NSArray *chatbuttonConstraintHeight = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[chatbutton(buttonHeight)]"
                                                                                options:0
                                                                                metrics:metrics
                                                                                  views:viewsDictionary];
    
    [self.chatButton addConstraints:chatbuttonConstraintHeight];
    [self.chatButton addConstraints:chatbuttonConstraintWidth];
    
    
    //constraints for callbutton
    NSArray *callbuttonConstraintWidth = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[callbutton(callbuttonWidth)]"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:viewsDictionary];
    
    NSArray *callbuttonConstraintHeight = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[callbutton(buttonHeight)]"
                                                                                  options:0
                                                                                  metrics:metrics
                                                                                    views:viewsDictionary];
    
    [self.callButton addConstraints:callbuttonConstraintHeight];
    [self.callButton addConstraints:callbuttonConstraintWidth];
    
    //constraints for reviewbutton
    NSArray *reviewbuttonConstraintWidth = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[reviewbutton(reviewbuttonWidth)]"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:viewsDictionary];
    
    NSArray *reviewbuttonConstraintHeight = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[reviewbutton(buttonHeight)]"
                                                                                  options:0
                                                                                  metrics:metrics
                                                                                    views:viewsDictionary];
    
    [self.reviewButton addConstraints:reviewbuttonConstraintHeight];
    [self.reviewButton addConstraints:reviewbuttonConstraintWidth];
    
    // contraints between views
    NSArray *image_name_constraint_h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[userimage]-viewSpacing-[username]"
                                                                               options:0
                                                                               metrics:metrics
                                                                                 views:viewsDictionary];
    
    NSArray *image_info_constraint_h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[userimage]-viewSpacing-[userinfo]"
                                                                               options:0
                                                                               metrics:metrics
                                                                                 views:viewsDictionary];
    
    NSArray *name_container_constraint_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topMargin-[username]"
                                                                               options:0
                                                                               metrics:metrics
                                                                                 views:viewsDictionary];
    
    NSArray *info_name_constraint_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[username]-0-[userinfo]"
                                                                                   options:0
                                                                                   metrics:metrics
                                                                                     views:viewsDictionary];
    
    NSArray *userimage_service_constraint_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[userimage]-10-[service]-10-[chatbutton]"
                                                                                      options:0
                                                                                      metrics:metrics
                                                                                        views:viewsDictionary];
    
    
    
    NSArray *service_margin_constraint_h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[service]-10-|"
                                                                                      options:0
                                                                                      metrics:metrics
                                                                                        views:viewsDictionary];
    
    
    NSArray *chatbutton_bottom_constraint_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[chatbutton]-bottomMargin-|"
                                                                              options:0
                                                                              metrics:metrics
                                                                                views:viewsDictionary];
    
    NSArray *callbutton_bottom_constraint_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[callbutton]-bottomMargin-|"
                                                                                      options:0
                                                                                      metrics:metrics
                                                                                        views:viewsDictionary];
    NSArray *reviewbutton_bottom_constraint_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[reviewbutton]-bottomMargin-|"
                                                                                      options:0
                                                                                      metrics:metrics
                                                                                        views:viewsDictionary];
    
    NSArray *review_call_chat_constraint_h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leftMargin-[chatbutton]-viewSpacing-[callbutton]-viewSpacing-[reviewbutton]"
                                                                                        options:0
                                                                                        metrics:metrics
                                                                                          views:viewsDictionary];
    
    
    [self.container addConstraints:image_name_constraint_h];
    [self.container addConstraints:image_info_constraint_h];
    [self.container addConstraints:name_container_constraint_v];
    [self.container addConstraints:info_name_constraint_v];
    [self.container addConstraints:userimage_service_constraint_v];
    [self.container addConstraints:service_margin_constraint_h];
    [self.container addConstraints:review_call_chat_constraint_h];
    [self.container addConstraints:callbutton_bottom_constraint_v];
    [self.container addConstraints:chatbutton_bottom_constraint_v];
    [self.container addConstraints:reviewbutton_bottom_constraint_v];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark LoginViewControllerDelegate methods

-(void)loginComplete{
    if(loginCompletionBlock != nil){
        loginCompletionBlock();
        loginCompletionBlock = nil;
    }
}

#pragma mark button actions

-(void)startChat
{
    NSLog(@"start chat called");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(![defaults objectForKey:AUTH_DATA] || self.cleanerInfo == nil){
        NSLog(@"unable to start chat");
        LoginViewController *logInViewController = [[LoginViewController alloc] init];
        logInViewController.delegate = self;
        [self presentViewController:logInViewController animated:YES completion:nil];
        __weak typeof(self) weakSelf = self;
        loginCompletionBlock = ^(void){
            [weakSelf startChat];
        };
        return;
    }
    
    Firebase *fireBase = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
    NSMutableDictionary *updateDict = [NSMutableDictionary new];
    
    // add other user's info to other this user's own chats
    NSString *userUID = [defaults objectForKey:UID];
    updateDict[@"name"] = self.cleanerInfo[@"name"];
    updateDict[@"profile_url"] = self.cleanerInfo[@"profile_url"];
    updateDict[@"message"] = @"New chat.";
    updateDict[@"uid"] = self.cleanerInfo[@"uid"];
    updateDict[@"date"] = [Utility dateStringNowWithFormat:DATE_FORMAT_STRING];
    updateDict[@"status"] = @"unread";
    Firebase *chatCleanerBase = [fireBase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@",CHATS_LIST,userUID,self.cleanerInfo[@"uid"]]];
    [chatCleanerBase setValue:updateDict];
    
    // add this user's info to other user's chats
    NSDictionary * myInfoDefault = [defaults objectForKey:AUTH_DATA];
    updateDict = [NSMutableDictionary new];
    updateDict[@"name"] = myInfoDefault[@"displayName"];
    updateDict[@"profile_url"] = myInfoDefault[@"cachedUserProfile"][@"picture"][@"data"][@"url"];
    updateDict[@"uid"] = userUID;
    updateDict[@"message"] = @"New chat.";
    updateDict[@"status"] = @"unread";
    updateDict[@"date"] = [Utility dateStringNowWithFormat:DATE_FORMAT_STRING];
    Firebase *otherCleanerBase = [fireBase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@",CHATS_LIST,self.cleanerInfo[@"uid"],userUID]];
    [otherCleanerBase setValue:updateDict];
    
    NSString * uid = self.cleanerInfo[@"uid"];
    MessageViewController *messageViewController;
    if([_chatMessageViewControllerCache objectForKey:uid] != nil){
        messageViewController = [_chatMessageViewControllerCache objectForKey:uid];
    }else{
        messageViewController = [MessageViewController new];
        messageViewController.otherId = self.cleanerInfo[@"uid"];
        messageViewController.otherDisplayName = self.cleanerInfo[@"name"];
        [_chatMessageViewControllerCache setObject:messageViewController forKey:uid];
    }
    [self.navigationController pushViewController:messageViewController animated:YES];
}

-(void)startCall
{
    NSString *phNo = self.cleanerInfo[@"phone"];
    NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",phNo]];
    
    if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
        [[UIApplication sharedApplication] openURL:phoneUrl];
    } else
    {
        UIAlertView * calert = [[UIAlertView alloc]initWithTitle:@"Opps :P" message:@"This number is not callable." delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
        [calert show];
    }
    
}

-(void)addReview
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(![defaults objectForKey:AUTH_DATA]){
        LoginViewController *logInViewController = [[LoginViewController alloc] init];
        logInViewController.delegate = self;
        [self presentViewController:logInViewController animated:YES completion:nil];
        __weak typeof(self) weakSelf = self;
        loginCompletionBlock = ^(void){
            [weakSelf addReview];
        };
        return;
    }
    
    EditReviewController *reviewViewController = [EditReviewController new];
    reviewViewController.cleanerUID = self.cleanerInfo[@"uid"];
    [self.navigationController pushViewController:reviewViewController animated:YES];
}


#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   // UIImage *profileImage = [UIImage imageNamed:@"anna.jpg"];
    
    NSDictionary *reviewInfo = [reviews objectAtIndex:indexPath.row];
    CleanerReviewCell *cell = (CleanerReviewCell *)[tableView dequeueReusableCellWithIdentifier:CleanerCellIdentifier];
    UIImage *profileImage = [ImageProcessor imageFromURL:reviewInfo[@"cachedUserProfile"][@"picture"][@"data"][@"url"]];
    if(profileImage == nil){
        profileImage = [UIImage imageNamed:@"missingAvatar.png"];
    }
    [cell.userimage setImage:[ImageProcessor roundCorneredImage:profileImage radius:15]];
    [cell.review setText:reviewInfo[@"review_text"]];
    [cell.username setText:reviewInfo[@"displayName"]];

    cell.staticStarRatingView.canEdit = NO;
    cell.staticStarRatingView.maxRating = 5;
    cell.staticStarRatingView.rating = [reviewInfo[@"review_rating"] floatValue];
    cell.staticStarRatingView.delegate = self;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [reviews count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *reviewInfo = [reviews objectAtIndex:indexPath.row];
    EditReviewController * reviewController = [EditReviewController new];
    reviewController.reviewInfo = reviewInfo;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.navigationController pushViewController:reviewController animated:YES];
}

#pragma mark ASStarRatingViewDelegate methods

-(void)bubbleTouchUp:(NSSet *)touches{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchLocation];
    [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

@end
