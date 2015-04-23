//
//  ChatBubbleViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 1/21/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIBubbleTableViewDataSource.h"
#import "UIBubbleTableView.h"
#import "CameraPopUpTableViewController.h"

@interface ChatBubbleViewController : UIViewController <UIBubbleTableViewDataSource,
                                                        UIBubbleTableViewDelegate,
                                                        UITextViewDelegate,
                                                        UIActionSheetDelegate,
                                                        CameraPopUpTableViewControllerDelegate,
                                                        UIImagePickerControllerDelegate,
                                                        UINavigationControllerDelegate>
@property (nonatomic,weak) NSString * otherId;
@property (nonatomic,weak) NSString * otherImageURL;
@end
