//
//  MessageViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 3/30/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessages.h"
#import "MessageData.h"

@interface MessageViewController : JSQMessagesViewController <UIActionSheetDelegate,MessageDataDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (strong,nonatomic) NSString * otherId;
@property (strong,nonatomic) NSString * otherDisplayName;
@end
