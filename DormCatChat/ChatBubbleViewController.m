//
//  ChatBubbleViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 1/21/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "ChatBubbleViewController.h"
#import "UIBubbleTableView.h"
#import "UIBubbleTableViewDataSource.h"
#import "NSBubbleData.h"
#import "Macro.h"
#import "RDRStickyKeyboardView.h"
#import <Firebase/Firebase.h>
#import "MBProgressHUD.h"
#import "ImageProcessor.h"
#import "DXPopover.h"
#import "CameraPopUpTableViewController.h"
#import "NSStringAdditions.h"
#import <Parse/Parse.h>
#import "limits.h"
#import "AppDelegate.h"
#import "Utility.h"

typedef enum {
    UserMe,
    UserOther
} ChatUser;

@interface ChatBubbleViewController  ()
{
   UIView *inputView;
   UITextView *inputTextView;
   UIButton *sendButton;
   UIButton *cameraButton;
   UIBubbleTableView *bubbleTable;
   NSMutableArray *bubbleData;
   BOOL keyboardShown;
    
   //the popup views used when the camera button is pressed
   UITableView *cameraPopUpTableView;
   DXPopover *popover;
   CameraPopUpTableViewController *cameraPopUpTableViewController;
   BOOL cameraPopUpShown;
   NSInteger messageEndKey;
   NSInteger messageCntPerLoad;
}
@end

@implementation ChatBubbleViewController{
    Firebase * myChatRef;
    Firebase * otherChatRef;
    NSString * myId;
    long messageCount; // index of the last message;
    BOOL loadPrevious;
    BOOL initialLoad; // whether loading previous msg is the first one
    BOOL shouldLoadMore; // if this previous msg loading has data then shouldLoadMore is true
    MBProgressHUD * HUD;
    UIImage *myImage;
    UIImage *otherImage;
    NSLayoutConstraint *inputViewBottomViewConstraint;
    NSLayoutConstraint *inputTextViewHeight;
    NSString *lastMessageString;
    NSCache * _imageCache;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    shouldLoadMore = YES;
    messageEndKey = INT16_MAX;
    messageCntPerLoad = 10;
    initialLoad = YES;
    lastMessageString = @"No message yet";
    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSDictionary *userData = [defaults objectForKey:AUTH_DATA];
//    myId = [defaults objectForKey:UID];// must use UID;
//    
//    Firebase * fbRootRef = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
//
//    NSString * myAppendString = [NSString stringWithFormat:@"chats/%@/%@",myId,self.otherId];
//    myChatRef = [fbRootRef childByAppendingPath:myAppendString];
//    NSString * otherAppendString = [NSString stringWithFormat:@"chats/%@/%@",self.otherId,myId];
//    otherChatRef = [fbRootRef childByAppendingPath:otherAppendString];
//    
//    // set up avatar
//    NSString *imageStringURLString = userData[@"cachedUserProfile"][@"picture"][@"data"][@"url"];
//    myImage = [ImageProcessor imageFromURLOrCache:imageStringURLString];
//    if(myImage != nil)
//        myImage = [ImageProcessor roundCorneredImage:myImage radius:15];
//    
//    otherImage = [ImageProcessor imageFromURLOrCache:self.otherImageURL];
//    if(otherImage != nil)
//        otherImage = [ImageProcessor roundCorneredImage:otherImage radius:15];
    
    [self testTableViews];
    
 //   [self setUpViews];
  //  [self setUpPopUpViews];
    // Keyboard events
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    //resign keyboard when user taps elsewhere
//    UITapGestureRecognizer* tapBackground = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
//    [tapBackground setNumberOfTapsRequired:1];
//    [bubbleTable addGestureRecognizer:tapBackground];
    
    // load the first ten data;
   // [self loadData:messageCntPerLoad endingAt:messageEndKey];
}

-(void)viewDidAppear:(BOOL)animated
{
    NSDictionary * dict= @{@"status":@"read"};
    [self update:UserMe ChatListWithDict:dict]; //update meta data
    if(cameraPopUpShown){
        cameraButton = NO;
    }
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.
        // update both user's cleaner chat field;
        NSInteger unreadMsgCnt = 0;
        for(NSBubbleData * data in bubbleData){
            if([data.status isEqualToString:@"unread"]){
                unreadMsgCnt++;
                [self updateMessageWithKey:data.key toReadStatus:YES];
                data.status = @"read";
            }
        }
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate decrementUnreadMessagesNumberBy:unreadMsgCnt];
        [appDelegate updateNotificationNumberToChatViewController];
    }
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(void)dealloc{
    NSLog(@"dealloc");
}

-(void)setUpPopUpViews{
    cameraPopUpShown = NO;
    cameraPopUpTableViewController = [CameraPopUpTableViewController new];
    cameraPopUpTableViewController.delegate = self;
    cameraPopUpTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 120, 100) style:UITableViewStyleGrouped];
    cameraPopUpTableView.scrollEnabled = NO;
    cameraPopUpTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, cameraPopUpTableView.bounds.size.width, 0.01f)];
    cameraPopUpTableView.rowHeight = 50;
    cameraPopUpTableView.delegate = cameraPopUpTableViewController;
    cameraPopUpTableView.dataSource = cameraPopUpTableViewController;
    cameraPopUpTableView.backgroundColor = [UIColor whiteColor];
    popover = [DXPopover new];
}

-(void)testTableViews
{
    self.view.backgroundColor = [UIColor whiteColor];
    bubbleTable = [[UIBubbleTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
   // bubbleTable.translatesAutoresizingMaskIntoConstraints = NO;
    bubbleTable.bubbleDataSource = self;
    bubbleTable.containerDelegate = self;
    [self.view addSubview:bubbleTable];
    
    [bubbleTable addObserver:self forKeyPath:@"contentSize" options:0 context:NULL];
    
    NSBubbleData *heyBubble = [NSBubbleData dataWithText:@"Hey, halloween is soon" date:[NSDate dateWithTimeIntervalSinceNow:-300] type:BubbleTypeSomeoneElse];
    heyBubble.avatar = [UIImage imageNamed:@"avatar1.png"];
    
    NSBubbleData *photoBubble = [NSBubbleData dataWithImage:[UIImage imageNamed:@"halloween.jpg"] date:[NSDate dateWithTimeIntervalSinceNow:-290] type:BubbleTypeSomeoneElse];
    photoBubble.avatar = [UIImage imageNamed:@"avatar1.png"];
    
    NSBubbleData *replyBubble = [NSBubbleData dataWithText:@"Wow.. Really cool picture out there. iPhone 5 has really nice camera, yeah?" date:[NSDate dateWithTimeIntervalSinceNow:-5] type:BubbleTypeMine];
    replyBubble.avatar = nil;
    
    bubbleData = [[NSMutableArray alloc] initWithObjects:heyBubble, photoBubble, replyBubble, nil];
    bubbleTable.bubbleDataSource = self;
    
    // The line below sets the snap interval in seconds. This defines how the bubbles will be grouped in time.
    // Interval of 120 means that if the next messages comes in 2 minutes since the last message, it will be added into the same group.
    // Groups are delimited with header which contains date and time for the first message in the group.
    
    bubbleTable.snapInterval = 120;
    
    // The line below enables avatar support. Avatar can be specified for each bubble with .avatar property of NSBubbleData.
    // Avatars are enabled for the whole table at once. If particular NSBubbleData misses the avatar, a default placeholder will be set (missingAvatar.png)
    
    bubbleTable.showAvatars = YES;
    
    // Uncomment the line below to add "Now typing" bubble
    // Possible values are
    //    - NSBubbleTypingTypeSomebody - shows "now typing" bubble on the left
    //    - NSBubbleTypingTypeMe - shows "now typing" bubble on the right
    //    - NSBubbleTypingTypeNone - no "now typing" bubble
    
    bubbleTable.typingBubble = NSBubbleTypingTypeSomebody;
    bubbleTable.rowHeight = 80;
    [bubbleTable reloadData];
    
    NSLog(@"self.view height %f",self.view.bounds.size.height);
    NSLog(@"self.view width %f",self.view.bounds.size.width);
    NSLog(@"bubbleTable height %f",bubbleTable.bounds.size.height);
    NSLog(@"bubbleTable width %f",bubbleTable.bounds.size.width);
    NSLog(@"scroll content height %f",bubbleTable.contentSize.height);
    NSLog(@"scroll content Width %f",bubbleTable.contentSize.width);
}

-(void)setUpViews{
    // setup camera popup view
    bubbleTable = [UIBubbleTableView new];
    bubbleTable.translatesAutoresizingMaskIntoConstraints = NO;
    bubbleTable.bubbleDataSource = self;
    bubbleTable.containerDelegate = self;
    
    inputView = [UIView new];
    inputView.translatesAutoresizingMaskIntoConstraints = NO;
    inputView.backgroundColor = [UIColor whiteColor];
    
    inputTextView = [UITextView new];
    inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    inputTextView.scrollEnabled = NO; // super important if set to YES leads to jumpy animation !!!!
    [inputTextView setFont:[UIFont fontWithName:AVENIR_LIGHT size:13]];
    
    cameraButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cameraButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cameraButton setImage:[UIImage imageNamed:@"camera.png"] forState:UIControlStateNormal];
    [cameraButton setTintColor:[UIColor grayColor]];
    [cameraButton addTarget:self action:@selector(sendPicture) forControlEvents:UIControlEventTouchDown];
    
    sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [sendButton setTintColor:[UIColor grayColor]];
    [sendButton addTarget:self action:@selector(sendMsg) forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview:bubbleTable];
//    [inputView addSubview:sendButton];
//    [inputView addSubview:cameraButton];
//    [inputView addSubview:inputTextView];
//    [self.view addSubview:inputView];
    
    NSDictionary *viewsDictionary = @{@"inputTextView":inputTextView,
                                      @"inputView":inputView,
                                      @"bubbleTable":bubbleTable,
                                      @"cameraBtn":cameraButton,
                                      @"sendBtn":sendButton
                                      };
//
//    NSLayoutConstraint *input_view_height = [NSLayoutConstraint constraintWithItem:inputTextView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:30];
//    [inputTextView addConstraint:input_view_height];
//     inputTextViewHeight = input_view_height;
//    
//    NSArray *camera_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10.0)-[cameraBtn]"
//                                                                options:0
//                                                                metrics:nil
//                                                                  views:viewsDictionary];
//    
//    NSArray *send_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(5.0)-[sendBtn(30.0)]"
//                                                                options:0
//                                                                metrics:nil
//                                                                  views:viewsDictionary];
//    
//    NSArray *input_text_view_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(5.0)-[inputTextView]-(5.0)-|"
//                                                                              options:0
//                                                                              metrics:nil
//                                                                           views:viewsDictionary];
//    
//    NSArray *input_text_view_h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[cameraBtn]-(15.0)-[inputTextView(200)]-(10.0)-[sendBtn]"
//                                                                         options:0
//                                                                         metrics:nil
//                                                                           views:viewsDictionary];
//    
//    NSLayoutConstraint *xContraint = [NSLayoutConstraint constraintWithItem:inputTextView
//                                                                  attribute:NSLayoutAttributeCenterX
//                                                                  relatedBy:NSLayoutRelationEqual
//                                                                     toItem:inputView
//                                                                  attribute:NSLayoutAttributeCenterX
//                                                                 multiplier:1.0
//                                                                   constant:0];
//    
//    [inputView addConstraint:xContraint];
//    [inputView addConstraints:camera_v];
//    [inputView addConstraints:send_v];
//    [inputView addConstraints:input_text_view_v];
//    [inputView addConstraints:input_text_view_h];
//    
    NSArray *input_view_bubbletable_v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[bubbleTable]-(0)-|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:viewsDictionary];
//
//    NSLayoutConstraint *input_view_v = [NSLayoutConstraint constraintWithItem:inputView
//                                                                    attribute:NSLayoutAttributeBottom
//                                                                    relatedBy:NSLayoutRelationEqual
//                                                                       toItem:self.view
//                                                                    attribute:NSLayoutAttributeBottom
//                                                                   multiplier:1.0
//                                                                     constant:0];
//    
     NSArray *bubbletable_h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[bubbleTable]-(0)-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:viewsDictionary];
//
//    NSArray *inputView_h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[inputView]-(0)-|"
//                                                                     options:0
//                                                                     metrics:nil
//                                                                       views:viewsDictionary];
//    
//    xContraint = [NSLayoutConstraint constraintWithItem:inputView
//                                                                  attribute:NSLayoutAttributeCenterX
//                                                                  relatedBy:NSLayoutRelationEqual
//                                                                     toItem:self.view
//                                                                  attribute:NSLayoutAttributeCenterX
//                                                                 multiplier:1.0
//                                                                   constant:0];
    
      [self.view addConstraints:input_view_bubbletable_v];
//    [self.view addConstraint:input_view_v];
      [self.view addConstraints:bubbletable_h];
//    [self.view addConstraints:inputView_h];
//    [self.view addConstraint:xContraint];
    
//    inputViewBottomViewConstraint = input_view_v;
//    
//    inputTextView.layer.cornerRadius = 8;
//    inputTextView.layer.borderWidth = 1.0f;
//    inputTextView.layer.borderColor = [UIColorFromRGB(FLAT_GRAY) CGColor];
//    inputTextView.delegate = self;
    
    // The line below sets the snap interval in seconds. This defines how the bubbles will be grouped in time.
    // Interval of 120 means that if the next messages comes in 2 minutes since the last message, it will be added into the same group.
    // Groups are delimited with header which contains date and time for the first message in the group.
    
    bubbleTable.snapInterval = 120;
    
    // The line below enables avatar support. Avatar can be specified for each bubble with .avatar property of NSBubbleData.
    // Avatars are enabled for the whole table at once. If particular NSBubbleData misses the avatar, a default placeholder will be set (missingAvatar.png)
    
    bubbleTable.showAvatars = YES;
    
    // Uncomment the line below to add "Now typing" bubble
    // Possible values are
    //    - NSBubbleTypingTypeSomebody - shows "now typing" bubble on the left
    //    - NSBubbleTypingTypeMe - shows "now typing" bubble on the right
    //    - NSBubbleTypingTypeNone - no "now typing" bubble
    
    // bubbleTable.typingBubble = NSBubbleTypingTypeSomebody;
    
    self.view.backgroundColor = UIColorFromRGB(CHAT_BACKGROUND);
    //bubbleTable.backgroundView = nil;
    bubbleTable.backgroundColor = [UIColor blackColor];//UIColorFromRGB(CHAT_BACKGROUND);
    loadPrevious = YES;
   // bubbleData = [[NSMutableArray alloc] init];
    NSBubbleData *heyBubble = [NSBubbleData dataWithText:@"Hey, halloween is soon" date:[NSDate dateWithTimeIntervalSinceNow:-300] type:BubbleTypeSomeoneElse];
    heyBubble.avatar = [UIImage imageNamed:@"avatar1.png"];
    
    NSBubbleData *photoBubble = [NSBubbleData dataWithImage:[UIImage imageNamed:@"halloween.jpg"] date:[NSDate dateWithTimeIntervalSinceNow:-290] type:BubbleTypeSomeoneElse];
    photoBubble.avatar = [UIImage imageNamed:@"avatar1.png"];
    
    NSBubbleData *replyBubble = [NSBubbleData dataWithText:@"Wow.. Really cool picture out there. iPhone 5 has really nice camera, yeah?" date:[NSDate dateWithTimeIntervalSinceNow:-5] type:BubbleTypeMine];
    replyBubble.avatar = nil;
    
    bubbleData = [[NSMutableArray alloc] initWithObjects:heyBubble, photoBubble, replyBubble, nil];
}

-(void)loadData:(NSInteger)limit endingAt:(NSInteger)end
{
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.color = UIColorFromRGB(FLAT_GREEN);
    [self.view addSubview:HUD];
    HUD.minSize = CGSizeMake(50.f, 50.f);
    [HUD show:YES];
    
    NSMutableArray *array = [NSMutableArray new]; // use this array to reverse the data;
    
    FQuery *query = [[[myChatRef queryOrderedByKey] queryEndingAtValue:[NSString stringWithFormat:@"%d",end]] queryLimitedToLast:limit];
    NSLog(@"main %@", [NSThread currentThread]);
    [query observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot){
        NSBubbleData * data = [self createBubbleDataFromSnapShot:snapshot.value withKey:snapshot.key];
        NSLog(@"thread %@", [NSThread currentThread]);
        if(loadPrevious){
            [array insertObject:data atIndex:0];
        }else{
            // should directly append to bubbleData
            [bubbleData addObject:data];
        }
        
       /* if([snapshot.value[@"status"] isEqualToString:@"unread"]){
            unreadMsgCnt++;
            // update the status of that message to be read
            [self updateMessageWithKey:snapshot.key toReadStatus:YES];
        } */
        
        NSInteger msgKey = [snapshot.key intValue];
        
        // update message key
        if(msgKey > messageCount){
            messageCount = msgKey;
            if(snapshot.value[@"message"] != nil){
                lastMessageString = snapshot.value[@"message"];
            }else if(snapshot.value[@"image"] != nil){
                lastMessageString = @"Image";
            }
        }
        
        if(msgKey < messageEndKey){
            messageEndKey = msgKey;
        }
        
        if(!loadPrevious){
            [self updateMessageWithKey:snapshot.key toReadStatus:YES];
            [bubbleTable reloadData];
            [self scrollToBottom];
        }
    }];
    
    [query observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        // Reload the table view so that the intial messages show up
        [HUD hide:YES];
        if(loadPrevious){
            if([array count] == 0){
                shouldLoadMore = NO; // there is no more data to be load;
            }else{
                shouldLoadMore = YES;
                for(int i=0;i<[array count];i++){
                    [bubbleData insertObject:array[i] atIndex:0];
                }
                if(initialLoad){
                    initialLoad = NO;
                    [bubbleTable reloadData];
                }else{ // must be subsequent scroll load
                    CGFloat oldOffset = bubbleTable.contentOffset.y;
                    CGFloat oldTableHeight = bubbleTable.contentSize.height;
                     bubbleTable.contentSize = CGSizeMake(bubbleTable.bounds.size.width, bubbleTable.bounds.size.height);
                    [bubbleTable reloadData];
                    CGFloat newTableHeight = bubbleTable.contentSize.height;
                    [bubbleTable setContentOffset:CGPointMake(0,newTableHeight - oldTableHeight + oldOffset)];
                    if(messageEndKey > 1 )
                        [bubbleTable loadComplete];
                }
                
                [array removeAllObjects];
            }
        }
        loadPrevious = NO;
    }];
}

-(NSBubbleData *)createBubbleDataFromSnapShot:(NSDictionary *)dict withKey:(NSString *)key
{
    NSBubbleType bubbleType;
    NSBubbleData *bubble;
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT_STRING];
    NSDate *date = [dateFormatter dateFromString:dict[@"date"]];
    
    if([dict[@"from"] isEqual:ME]){
        bubbleType = BubbleTypeMine;
        if(dict[@"image"] != nil){
            NSData *dataFromBase64=[NSData base64DataFromString:dict[@"image"]];
            UIImage *image = [[UIImage alloc]initWithData:dataFromBase64];
            bubble = [NSBubbleData dataWithImage:image date:date type:bubbleType];
        }else if(dict[@"message"]!=nil){
            bubble = [NSBubbleData dataWithText:dict[@"message"] date:date type:bubbleType];
        }
        bubble.avatar = myImage;
    }else{
        bubbleType = BubbleTypeSomeoneElse;
        if(dict[@"image"] != nil){
            NSData *dataFromBase64=[NSData base64DataFromString:dict[@"image"]];
            UIImage *image = [[UIImage alloc]initWithData:dataFromBase64];
            bubble = [NSBubbleData dataWithImage:image date:date type:bubbleType];
        }else if(dict[@"message"]!=nil){
            bubble = [NSBubbleData dataWithText:dict[@"message"] date:date type:bubbleType];
        }
        bubble.avatar = otherImage;
    }
    bubble.status = dict[@"status"];
    bubble.key = key;
    return bubble;
}

#pragma mark UIBubbleTableViewDelegate methods

-(void)bubbleTableViewReachedTop{
//    loadPrevious = YES;
//    if(shouldLoadMore)
//        [self loadData:messageCntPerLoad endingAt:messageEndKey-1];
}

-(void)bubbleTableViewWillScroll{
    [self dismissKeyboard];
}
#pragma mark UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)textView{
    CGSize sizeThatFits = [textView sizeThatFits:textView.frame.size];
    float newHeight = sizeThatFits.height;
    [self.view layoutIfNeeded];
    inputTextViewHeight.constant = newHeight;
    [UIView animateWithDuration:1.0 animations:^(){
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - UIBubbleTableViewDataSource implementation

- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    return [bubbleData count];
}

- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    return [bubbleData objectAtIndex:row];
}

#pragma mark - Keyboard events

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSLog(@"keyboard was shown");
    NSDictionary* userInfo = [aNotification userInfo];
    CGSize kbSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [self.view layoutIfNeeded];
    [UIView animateKeyframesWithDuration:duration delay:0 options:(curve << 16) animations:^{
        CGFloat offset = abs(inputViewBottomViewConstraint.constant) - kbSize.height;
         inputViewBottomViewConstraint.constant += offset;
        [self.view layoutIfNeeded];
    } completion:nil];
    
    [self scrollToBottom];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSLog(@"keyboard will be hidden");
    NSDictionary* userInfo = [aNotification userInfo];
    CGSize kbSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [self.view layoutIfNeeded];
    [UIView animateKeyframesWithDuration:duration delay:0 options:(curve << 16) animations:^{
        CGFloat offset = kbSize.height;
        inputViewBottomViewConstraint.constant += offset;
        [self.view layoutIfNeeded];
    } completion:nil];
}

-(void)scrollToBottom
{
    long sectionIndex = [bubbleTable numberOfSections]-1;
    if(sectionIndex >= 0){
        long lastRowNumber = [bubbleTable numberOfRowsInSection:sectionIndex] - 1;
        if(lastRowNumber >= 0){
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:lastRowNumber inSection:sectionIndex];
            [bubbleTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
}

#pragma mark - CameraPopUpTableViewControllerDelegate methods

-(void)cellTapped:(NSIndexPath *)indexPath
{
    cameraPopUpShown = YES;
    if(indexPath.row == 0){
        [self takePhoto];
    }else{
        [self choosePhoto];
    }
}
#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    lastMessageString = @"Image";
    [picker dismissViewControllerAnimated:YES completion:^{
        messageCount++;
        NSLog(@"received image");
        NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
        NSString *imageString = [NSString base64StringFromData:imageData length:[imageData length]];
        
        NSString *dateString = [self dateStringNowWithFormat:DATE_FORMAT_STRING];
        NSDictionary * msg = @{
                               @"from":ME,
                               @"image":imageString,
                               @"date": dateString
                               };
        
        NSDictionary * otherMsg = @{
                                    @"from":OTHER,
                                    @"image":imageString,
                                    @"date":dateString
                                    };
        
        Firebase * msgRef = [myChatRef childByAppendingPath:[NSString stringWithFormat:@"%ld",(long)messageCount]];
        [msgRef setValue:msg];
        
        Firebase * otherMsgRef = [otherChatRef childByAppendingPath:[NSString stringWithFormat:@"%ld",(long)messageCount]];
        [otherMsgRef setValue:otherMsg];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        PFQuery *pushQuery = [PFInstallation query];
        [pushQuery whereKey:UID equalTo:self.otherId];
        PFPush *push = [[PFPush alloc] init];
        [push setQuery:pushQuery];
        NSDictionary *payLoad = @{
                                  @"type":@"image",
                                  @"from":[defaults objectForKey:UID],
                                  @"message":@""
                                  };
        [push setData:payLoad];
        [push sendPushInBackground];
        
    }];
}

#pragma mark - Actions

-(void)takePhoto
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO){
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:NULL];
}

-(void)choosePhoto
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO){
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    NSLog(@"title %@",picker.navigationBar.topItem.title);
   // picker.navigationBar.topItem.title = nil;
    [Utility addTitleLabelToNavigationItem:picker.navigationBar.topItem withText:@""];
    [self presentViewController:picker animated:YES completion:NULL];
}

-(void)sendPicture
{
    CGPoint showPoint = inputView.frame.origin;
    showPoint.x += 4;
    popover.maskType = DXPopoverMaskTypeNone;
    [popover showAtPoint:showPoint popoverPostion:DXPopoverPositionUp withContentView:cameraPopUpTableView inView:self.view];
}

- (void)sendMsg
{
    messageCount++;
    NSString * msgToSend = lastMessageString = inputTextView.text;
    NSString *dateString = [self dateStringNowWithFormat:DATE_FORMAT_STRING];
    NSDictionary * msg = @{
                           @"from":ME,
                           @"message":msgToSend,
                           @"date":dateString,
                           @"status":@"unread"
                           };
    
    NSDictionary * otherMsg = @{
                                @"from":OTHER,
                                @"message":msgToSend,
                                @"date":dateString,
                                @"status":@"unread"
                                };
    // update chats
    Firebase * msgRef = [myChatRef childByAppendingPath:[NSString stringWithFormat:@"%ld",messageCount]];
    [msgRef setValue:msg];
    
    Firebase * otherMsgRef = [otherChatRef childByAppendingPath:[NSString stringWithFormat:@"%ld",messageCount]];
    [otherMsgRef setValue:otherMsg];
    
    // update ChatList
    NSMutableDictionary *chatListDict = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:msgToSend,@"unread",dateString, nil] forKeys:[NSArray arrayWithObjects:@"message",@"status",@"date", nil]];
    [self update:UserOther ChatListWithDict:chatListDict];
    
    // for my own chat list the status should be read
    chatListDict[@"status"] = @"read";
    [self update:UserMe ChatListWithDict:chatListDict];
    
    //send a push notification to the other device;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userID = [defaults objectForKey:UID];
    PFQuery *pushQuery = [PFInstallation query];
    NSLog(@"sending push to uid %@",self.otherId);
    [pushQuery whereKey:UID equalTo:self.otherId];
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery];
    NSDictionary *payLoad = @{
                              @"type":@"text",
                              @"from":userID,
                              @"message":inputTextView.text,
                              @"alert":inputTextView.text,
                              @"badge":@"Increment"
                              };
    [push setData:payLoad];
    [push sendPushInBackground];
    
    //clear the input text
    inputTextView.text = @"";
}

-(void)dismissKeyboard
{
    [inputTextView resignFirstResponder];
    [popover dismiss];
}

-(NSString *)dateStringNowWithFormat:(NSString *)format
{
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    NSString *dateString = [dateFormatter stringFromDate:now];
    return dateString;
}

-(void)updateMessageWithKey:(NSString *)key toReadStatus:(BOOL)read{
    Firebase * fireBase = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
    Firebase * myChatMsg = [fireBase childByAppendingPath:[NSString stringWithFormat:@"chats/%@/%@/%@",myId,self.otherId,key]];
    NSDictionary *updateMsgDict;
    if(read){
         updateMsgDict = @{@"status":@"read"};
    }else{
         updateMsgDict = @{@"status":@"unread"};
    }
    [myChatMsg updateChildValues:updateMsgDict];
//    Firebase * otherChatMsg = [fireBase childByAppendingPath:[NSString stringWithFormat:@"chats/%@/%@/%@",self.otherId,myId,key]];
//    [otherChatMsg updateChildValues:updateMsgDict];
}

-(void)update:(ChatUser)user ChatListWithDict:(NSDictionary *)dict
{
    Firebase * fireBase = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
    Firebase * chatsList;
    // update chats_list
    switch (user) {
        case UserMe:
            chatsList = [fireBase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@",CHATS_LIST,myId,self.otherId]];
            break;
        case UserOther:
            chatsList = [fireBase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@",CHATS_LIST,self.otherId,myId]];
            break;
        default:
            break;
    }
    [chatsList updateChildValues:dict];
}

#pragma mark UIImagePickerControllerDelegate method

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [Utility addTitleLabelToNavigationItem:viewController.navigationItem withText:@"Photos"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"observed");
}
@end
