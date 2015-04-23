

#import "MessageViewController.h"
#import "Macro.h"
#import <Firebase/Firebase.h>
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "Utility.h"
#import "AppDelegate.h"
#import "NSStringAdditions.h"
#import "OfferViewController.h"

typedef enum {
    UserMe,
    UserOther
} ChatUser;

@implementation MessageViewController{
    MessageData *messageData;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.senderId = [[NSUserDefaults standardUserDefaults] objectForKey:UID];
    self.senderDisplayName = [[NSUserDefaults standardUserDefaults] objectForKey:AUTH_DATA][@"displayName"];
    messageData = [MessageData new];
    
    messageData.users = @{self.senderId:self.senderDisplayName,
                          self.otherId:self.otherDisplayName
                          };
    messageData.selfId = self.senderId;
    messageData.otherId = self.otherId;
    messageData.delegate = self;
    
    self.collectionView.backgroundColor = UIColorFromRGB(CHAT_BACKGROUND);
    
    self.collectionView.loadEarlierMessagesHeaderTextColor = [UIColor grayColor];
    self.showLoadEarlierMessagesHeader = YES;
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f];
    [self loadPreviousData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSDictionary * dict= @{@"status":@"read"};
    [self update:UserMe chatListWithDict:dict]; //update meta data
   // self.collectionView.collectionViewLayout.springinessEnabled = YES;
}

-(void)viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        NSInteger unreadMsgCnt = 0;
        for(JSQMessage * msg in messageData.messages){
            if([msg.status isEqualToString:@"unread"]){
                unreadMsgCnt++;
                [messageData updateMessageWithKey:msg.key toReadStatus:YES];
                msg.status = @"read";
            }
        }
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate decrementUnreadMessagesNumberBy:unreadMsgCnt];
        [appDelegate updateNotificationNumberToChatViewController];
    }
    [super viewWillDisappear:animated];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    
   // [messageData.messages  addObject:message];
    
    [self saveDataToFirebase:message.text isImage:NO];
    [self finishSendingMessageAnimated:YES];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Choose photo",@"Take photo",@"Give offer", nil];
    [sheet showFromToolbar:self.inputToolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    switch (buttonIndex) {
        case 0:
            [self choosePhoto];
            break;
        case 1:
            [self takePhoto];
            break;
        case 2:
            [self sendOffer];
            break;
    }
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    [self finishSendingMessageAnimated:YES];
}

#pragma mark accessory actions

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
    [self presentViewController:picker animated:YES completion:NULL];
}

-(void)sendOffer
{
    JSQOfferMediaItem *offer = [JSQOfferMediaItem new];
    JSQMessage * msg = [[JSQMessage alloc] initWithSenderId:self.senderId senderDisplayName:self.senderDisplayName date:[NSDate date] media:offer];
    [messageData.messages addObject:msg];
    [self finishSendingMessageAnimated:YES];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [picker dismissViewControllerAnimated:YES completion:^{
        NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
        NSString *imageString = [NSString base64StringFromData:imageData length:[imageData length]];
        [self saveDataToFirebase:imageString isImage:YES];
    }];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [Utility addTitleLabelToNavigationItem:viewController.navigationItem withText:@"Photos"];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [messageData.messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [messageData.messages objectAtIndex:indexPath.item];
    NSLog(@"indexPath %@ senderId %@ otherId %@",indexPath,self.senderId,self.otherId);
    if ([message.senderId isEqualToString:self.senderId]) {
        NSLog(@"isEqualToSenderId");
        return messageData.outgoingBubbleImageData;
    }
    
    return messageData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [messageData.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [messageData.messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [messageData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [messageData.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [messageData.messages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}


#pragma mark - MessageDataDelegate

-(void)refreshView{
    [self.collectionView reloadData];
}

-(void)refreshViewAndScrollToBottom
{
    [self.collectionView reloadData];
    [self scrollToBottomAnimated:YES];
}

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [messageData.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [messageData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    [self loadPreviousData];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
    JSQMessage *message = [messageData.messages objectAtIndex:indexPath.row];
    if([message.media isKindOfClass:[JSQOfferMediaItem class]]){
        OfferViewController *offerViewController = [OfferViewController new];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.navigationController pushViewController:offerViewController animated:YES];
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

-(void)loadPreviousData
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.color = UIColorFromRGB(FLAT_GREEN);
    [messageData loadMorePreviousMessagesWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hide:YES];
        });
    }];
}

-(void)saveDataToFirebase:(NSString *)data isImage:(BOOL)isImage
{
    NSString *alertMsg;
    NSDictionary * selfMsg;
    NSDictionary * otherMsg;
    NSString *dateString = [Utility dateStringNowWithFormat:DATE_FORMAT_STRING];
    NSString *chatListString;
    NSDictionary *payLoad;
    NSString *userID = self.senderId;
    NSString * key = [NSString stringWithFormat:@"%lld",(long long)[[NSDate date] timeIntervalSince1970]];
    NSString * selfURLString = [NSString stringWithFormat:@"%@/chats/%@/%@/%@",FIREBASE_ROOT_URL,self.senderId,self.otherId,key];
    NSString * otherURLString = [NSString stringWithFormat:@"%@/chats/%@/%@/%@",FIREBASE_ROOT_URL,self.otherId,self.senderId,key];
    
    if(isImage){
        alertMsg = [NSString stringWithFormat:@"%@ sends you an image",self.senderDisplayName];
        selfMsg = @{
                   @"from":ME,
                   @"image":data,
                   @"date": dateString,
                   @"status":@"read"
                   };
        
        otherMsg = @{
                    @"from":OTHER,
                    @"image":data,
                    @"date":dateString,
                    @"status":@"unread"
                    };
        payLoad = @{
                    @"type":@"text",
                    @"from":userID,
                    @"alert":alertMsg,
                    @"badge":@"Increment"
                    };
        chatListString = @"image";
    }else{
        alertMsg = [NSString stringWithFormat:@"%@: %@",self.senderDisplayName,data];
        selfMsg = @{
                   @"from":ME,
                   @"message":data,
                   @"status":@"read",
                   @"date":dateString
                   };
        
        otherMsg = @{
                    @"from":OTHER,
                    @"message":data,
                    @"status":@"unread",
                    @"date":dateString
                    };
        
        payLoad = @{
                    @"type":@"text",
                    @"from":userID,
                    @"alert":alertMsg,
                    @"message":@"",
                    @"badge":@"Increment"
                    };
        chatListString = data;
    }
    
    Firebase * selfMsgRef = [[Firebase alloc] initWithUrl:selfURLString];
    [selfMsgRef setValue:selfMsg];
    Firebase * otherMsgRef = [[Firebase alloc] initWithUrl:otherURLString];
    [otherMsgRef setValue:otherMsg];
    
    // update ChatList
    NSMutableDictionary *chatListDict = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:chatListString,@"unread",dateString, nil] forKeys:[NSArray arrayWithObjects:@"message",@"status",@"date", nil]];
    [self update:UserOther chatListWithDict:chatListDict];
    
    // for the sender's chat list the status should be read
    chatListDict[@"status"] = @"read";
    [self update:UserMe chatListWithDict:chatListDict];
    
    //send a push notification to the other device;
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:UID equalTo:self.otherId];
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery];
    [push setData:payLoad];
    [push sendPushInBackground];
}

-(void)update:(ChatUser)user chatListWithDict:(NSDictionary *)dict
{
    Firebase * fireBase = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
    Firebase * chatsList;
    // update chats_list
    switch (user) {
        case UserMe:
            chatsList = [fireBase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@",CHATS_LIST,self.senderId,self.otherId]];
            break;
        case UserOther:
            chatsList = [fireBase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@",CHATS_LIST,self.otherId,self.senderId]];
            break;
        default:
            break;
    }
    [chatsList updateChildValues:dict];
}

@end
