//
//  BecomeCleanerViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 1/30/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditViewController.h"


@protocol CleanerAccountViewControllerDelegate <NSObject>
-(void)updateUIAfterSubmission;
@end

@interface CleanerAccountViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,EditViewControllerDelegate>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) id<CleanerAccountViewControllerDelegate> delegate;
@property (nonatomic,strong) NSArray * displayDetailArray; // usage type for this view controller;
@end
