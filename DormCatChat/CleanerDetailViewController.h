//
//  CleanerDetailViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 1/24/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"
#import "ASStarRatingView.h"

@interface CleanerDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,LoginViewControllerDelegate,ASStarRatingViewDelegate>
@property (nonatomic,strong) UIImageView *userimage;
@property (nonatomic,strong) UILabel *username;
@property (nonatomic,strong) UILabel *userinfo;
@property (nonatomic,strong) UITextView *service;
@property (nonatomic,strong) UIView *container;
@property (nonatomic,strong) UIButton *chatButton;
@property (nonatomic,strong) UIButton *callButton;
@property (nonatomic,strong) UIButton *reviewButton;
@property (nonatomic,strong) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSDictionary *cleanerInfo;
@end