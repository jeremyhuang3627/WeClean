//
//  CameraPopUpViewController.h
//  this serve as the delegate and data source for the cameraPopUpTableView in ChatBubbleViewController
//  DormCatChat
//
//  Created by Huang Jie on 2/23/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CameraPopUpTableViewControllerDelegate <NSObject>

-(void)cellTapped:(NSIndexPath *)indexPath;

@end

@interface CameraPopUpTableViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) id<CameraPopUpTableViewControllerDelegate> delegate;
@end
