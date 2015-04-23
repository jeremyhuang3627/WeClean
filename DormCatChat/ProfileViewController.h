//
//  SecondViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 1/18/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTabBarController.h"
#import "ASStarRatingView.h"
#import "SortPopUpTableViewController.h"

@interface ProfileViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,ASStarRatingViewDelegate,SortPopUpTableViewControllerDelegate>
@property (nonatomic,strong) DCTabBarController * parentTabBarController;
@property (nonatomic,strong) UITableView *tableView;
@end
