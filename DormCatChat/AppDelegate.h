//
//  AppDelegate.h
//  DormCatChat
//
//  Created by Huang Jie on 1/5/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "ChatViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) ChatViewController * chatViewController;
@property (strong, nonatomic) NSCache *chatBubbleViewControllerCache;
@property (strong, nonatomic) NSCache *globalImageCache; // global image cache;
-(void)updateLocation;
-(void)decrementUnreadMessagesNumberBy:(NSInteger)val;
-(void)updateNotificationNumberToChatViewController;
@end

