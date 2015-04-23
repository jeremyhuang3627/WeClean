//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "JSQMessages.h"

/**
 *  This is for demo/testing purposes only. 
 *  This object sets up some fake model data.
 *  Do not actually do anything like this.
 */

@protocol MessageDataDelegate <NSObject>
-(void)refreshView;
-(void)refreshViewAndScrollToBottom;
@end

@interface MessageData : NSObject

@property (strong, nonatomic) NSMutableArray *messages;

@property (strong, nonatomic) NSDictionary *avatars;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (strong, nonatomic) NSDictionary *users; // users map user id to user display name;

@property (strong, nonatomic) NSString * otherId;

@property (strong, nonatomic) NSString * selfId;

@property (strong, nonatomic) id<MessageDataDelegate> delegate;

@property (strong, nonatomic) NSNumber * unreadCnt;

- (void)addPhotoMediaMessage;
- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion;
- (void)loadMorePreviousMessagesWithBlock:(void (^)(void))completionBlock;
-(void)updateMessageWithKey:(NSString *)key toReadStatus:(BOOL)read;
@end
