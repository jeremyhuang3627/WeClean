#import "MessageData.h"
#import <Firebase/Firebase.h>
#import "Macro.h"
#import "NSStringAdditions.h"
#import "Utility.h"

/**
 *  This is for demo/testing purposes only.
 *  This object sets up some fake model data.
 *  Do not actually do anything like this.
 */

@implementation MessageData{
    long long messageEndKey;
    BOOL loadPrevious;
    BOOL initialLoad;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        messageEndKey = INT64_MAX;
        loadPrevious = YES;
        self.unreadCnt = [NSNumber numberWithInt:0];
        self.messages = [NSMutableArray new];
        
        JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
        self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
        self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:UIColorFromRGB(FLAT_GREEN)];
    }
    return self;
}

-(void)loadData:(NSInteger)limit endingAt:(long long)end completion:(void (^)(void))completionBlock
{
    NSLog(@"end is %lld",end);
    NSString * url = [NSString stringWithFormat:@"%@/chats/%@/%@",FIREBASE_ROOT_URL,self.selfId,self.otherId];
    Firebase * selfChatRef = [[Firebase alloc] initWithUrl:url];
    FQuery *query = [[[selfChatRef queryOrderedByKey] queryEndingAtValue:[NSString stringWithFormat:@"%lld",end]] queryLimitedToLast:limit];
    [query observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot){
        NSInteger msgKey = [snapshot.key intValue];
        JSQMessage *msg = [self snapshotToJSQMsg:snapshot];
        if(msg != nil){
            [self.messages addObject:msg];
            
            if(msgKey < messageEndKey){
                messageEndKey = msgKey;
            }
            
            if(!loadPrevious){
                [self.delegate refreshViewAndScrollToBottom];
            }
        }
    }];
    
    [query observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if(loadPrevious){
            loadPrevious = NO;
            //sort self.messages by date;
            self.messages = [[self.messages sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                JSQMessage * message1 = (JSQMessage *)obj1;
                JSQMessage * message2 = (JSQMessage *)obj2;
                return [message1.date compare:message2.date];
            }] mutableCopy] ;
            [self.delegate refreshView];
        }
        completionBlock();
    }];
}

-(void)loadMorePreviousMessagesWithBlock:(void (^)(void))completionBlock{
    loadPrevious = YES;
    [self loadData:10 endingAt:messageEndKey-1 completion:completionBlock];
}

-(JSQMessage *)snapshotToJSQMsg:(FDataSnapshot *)snapshot
{
    JSQMessage * returnMessage = nil;
    NSString * uid;
    NSString * displayName;
    
    if([snapshot.value[@"from"] isEqualToString:ME]){
        uid = self.selfId;
        displayName = self.users[self.selfId];
    }else{
        uid = self.otherId;
        displayName = self.users[self.otherId];
    }
    
    if(snapshot.value[@"message"] != nil){
        returnMessage = [[JSQMessage alloc] initWithSenderId:uid
                                           senderDisplayName:displayName
                                                        date:[NSDate dateWithTimeIntervalSince1970:[snapshot.key doubleValue]]
                                                       text:snapshot.value[@"message"]];
    }else if(snapshot.value[@"image"] != nil){
        NSData *dataFromBase64=[NSData base64DataFromString:snapshot.value[@"image"]];
        UIImage *image = [[UIImage alloc]initWithData:dataFromBase64];
        JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
        returnMessage = [[JSQMessage alloc] initWithSenderId:uid
                                            senderDisplayName:displayName
                                                        date:[NSDate dateWithTimeIntervalSince1970:[snapshot.key doubleValue]]
                                                   media:photoItem];
    }
    
    if(returnMessage != nil){
        returnMessage.status = snapshot.value[@"status"];
        returnMessage.key = snapshot.key;
    }
    
    return returnMessage;
}

-(void)updateMessageWithKey:(NSString *)key toReadStatus:(BOOL)read{
    Firebase * fireBase = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
    Firebase * myChatMsg = [fireBase childByAppendingPath:[NSString stringWithFormat:@"chats/%@/%@/%@",self.selfId,self.otherId,key]];
    NSDictionary *updateMsgDict;
    if(read){
        updateMsgDict = @{@"status":@"read"};
    }else{
        updateMsgDict = @{@"status":@"unread"};
    }
    [myChatMsg updateChildValues:updateMsgDict];
}

- (void)addPhotoMediaMessage
{
    
}

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion
{
    CLLocation *ferryBuildingInSF = [[CLLocation alloc] initWithLatitude:37.795313 longitude:-122.393757];
    
    JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
    [locationItem setLocation:ferryBuildingInSF withCompletionHandler:completion];
    
    JSQMessage *locationMessage = [JSQMessage messageWithSenderId:self.selfId
                                                      displayName:self.users[self.selfId]
                                                            media:locationItem];
    [self.messages addObject:locationMessage];
}
@end
