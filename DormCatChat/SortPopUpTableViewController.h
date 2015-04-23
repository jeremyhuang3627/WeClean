//
//  SortPopUpTableViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 3/14/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SortPopUpTableViewControllerDelegate <NSObject>

-(void)cellTapped:(NSIndexPath *)indexPath;

@end

@interface SortPopUpTableViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) id<SortPopUpTableViewControllerDelegate> delegate;
@end
