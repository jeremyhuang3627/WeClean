//
//  FirstViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 1/18/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DCTabBarController;

@interface ChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,strong) DCTabBarController * parentTabBarController;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *chatPeople;
-(void)updateChatsWithNotification:(NSDictionary *)notification;
-(void)updateChatLastMessage:(NSDictionary *)lastMessageDict WithID:(NSString *)uid;
-(void)loadData;
@end
