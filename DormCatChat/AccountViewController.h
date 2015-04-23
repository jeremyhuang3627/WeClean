//
//  ThirdViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 1/18/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>
#import "EditViewController.h"
#import "CleanerAccountViewController.h"

@class DCTabBarController;

@interface AccountViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,EditViewControllerDelegate,UIAlertViewDelegate,CleanerAccountViewControllerDelegate>
@property (nonatomic,strong) DCTabBarController * parentTabBarController;
@property (nonatomic,strong) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSDictionary *userData;
@property (nonatomic,strong) NSDictionary *cleanerData; // if not empty then user is cleaner
-(void)updateLoginUI;
@end
