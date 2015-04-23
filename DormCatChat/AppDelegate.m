//
//  AppDelegate.m
//  DormCatChat
//
//  Created by Huang Jie on 1/5/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "AppDelegate.h"
#import "ChatViewController.h"
#import "ProfileViewController.h"
#import "AccountViewController.h"
#import "DCTabBarController.h"
#import "DCTabBarItem.h"
#import "Macro.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>
#import <Firebase/Firebase.h>
#import "Utility.h"
#import "ChatBubbleViewController.h"
#import "MessageViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate{
    CLLocationManager *locationManager;
    NSDate *lastLocationUpdateTime;
    DCTabBarController * _tabBarController;
    PFInstallation *_currentInstallation;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.chatBubbleViewControllerCache = [NSCache new];
    self.globalImageCache = [NSCache new];
    
    [self setupViewControllers];
    [self.window setRootViewController:self.navigationController];
    [self.window makeKeyAndVisible];
    [self customizeInterface];
    
    [Parse setApplicationId:@"gPvEhsF4axMTjo6PASab078zOZQjRFGeygxMngsK"
                  clientKey:@"dMyikTKqeQRHGLSohR0ev3RzP66TgfdHdY4tYMpL"];
    
    //ios 8 and beyond
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
    // ios 7
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
    _currentInstallation = [PFInstallation currentInstallation];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Logs 'install' and 'app activate' App Events.
    [FBAppEvents activateApp];
    [FBAppCall handleDidBecomeActive];
    [self updateLocation];
    [self updateNotificationNumberToChatViewController];
    [self.chatViewController loadData];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
 
    NSLog(@"device token %@",deviceToken);
    [_currentInstallation setDeviceTokenFromData:deviceToken];
    [_currentInstallation saveInBackground];
    
    // clear the badge number for the app
    if(_currentInstallation.badge != 0){
        [self setBadgeNumber:0];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL inMessageView = [self.navigationController.topViewController isKindOfClass:[MessageViewController class]];
    if([defaults objectForKey:AUTH_DATA]
       && !inMessageView){
        [self setBadgeNumber:[userInfo[@"aps"][@"badge"] integerValue]];
        [self.chatViewController loadData];
    }else{
        // since each message sent increment the badge number, when the notification should be ignored, the badge number should be decremented;
        [self setBadgeNumber:[userInfo[@"aps"][@"badge"] integerValue] - 1];
    }
    
    NSLog(@"inMessageView %d",inMessageView);
}

#pragma mark - Login Methods

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [FBSession.activeSession handleOpenURL:url];
}

#pragma mark - UI Methods

- (void)setupViewControllers {
    ChatViewController *chatViewController = [[ChatViewController alloc] init];
    self.chatViewController = chatViewController;
    
    ProfileViewController *profileViewController = [[ProfileViewController alloc] init];
    AccountViewController *thirdViewController = [[AccountViewController alloc] init];
    
    DCTabBarController *tabBarController = [[DCTabBarController alloc] init];
    [tabBarController setViewControllers:@[profileViewController, chatViewController,
                                           thirdViewController]];
    
    profileViewController.parentTabBarController = tabBarController;
    chatViewController.parentTabBarController = tabBarController;
    thirdViewController.parentTabBarController = tabBarController;
    UINavigationController *rootNavigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:tabBarController];
  /*  UIImageView * catView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cat.png"]];
    tabBarController.navigationItem.titleView = catView; */
    self.navigationController = rootNavigationController;
    [self customizeTabBarForController:tabBarController];
    
    _tabBarController = tabBarController;
}

- (void)customizeTabBarForController:(DCTabBarController *)tabBarController {
    UIImage *finishedImage = [UIImage imageNamed:@"tabbar_selected_background"];
    UIImage *unfinishedImage = [UIImage imageNamed:@"tabbar_normal_background"];
    NSArray *tabBarItemImages = @[@"first",@"second",@"third"];
    
    NSInteger index = 0;
    for (DCTabBarItem *item in [[tabBarController tabBar] items]) {
        [item setBackgroundSelectedImage:finishedImage withUnselectedImage:unfinishedImage];
        UIImage *selectedimage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_selected",
                                                      [tabBarItemImages objectAtIndex:index]]];
        UIImage *unselectedimage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_normal",
                                                        [tabBarItemImages objectAtIndex:index]]];
        [item setFinishedSelectedImage:selectedimage withFinishedUnselectedImage:unselectedimage];
        index++;
    }

}

- (void)customizeInterface {
    UINavigationBar *navigationBarAppearance = [UINavigationBar appearance];
    UIImage *backgroundImage = nil;
    NSDictionary *textAttributes = nil;
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        backgroundImage = [UIImage imageNamed:@"navigationbar_background_tall"];
        textAttributes = @{
                           NSFontAttributeName: [UIFont boldSystemFontOfSize:18],
                           NSForegroundColorAttributeName: [UIColor blackColor],
                           };
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
        backgroundImage = [UIImage imageNamed:@"navigationbar_background"];
        
        textAttributes = @{
                           UITextAttributeFont: [UIFont boldSystemFontOfSize:18],
                           UITextAttributeTextColor: [UIColor blackColor],
                           UITextAttributeTextShadowColor: [UIColor clearColor],
                           UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                           };
#endif
    }
    
    [navigationBarAppearance setTintColor:[UIColor whiteColor]];
    [navigationBarAppearance setBackgroundImage:backgroundImage
                                  forBarMetrics:UIBarMetricsDefault];
    [navigationBarAppearance setTitleTextAttributes:textAttributes];
    //configure status bar
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)updateLocation
{
    if(locationManager == nil){
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    [locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate methods

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CLLocation* location = [locations lastObject];
        [self saveLocation:location];
        [locationManager stopUpdatingLocation];
    });
}

-(void)saveLocation:(CLLocation *)location
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *longitude = [NSString stringWithFormat:@"%f",location.coordinate.longitude];
    NSString *latitude = [NSString stringWithFormat:@"%f",location.coordinate.latitude];
    [defaults setObject:longitude forKey:LONGITUDE];
    [defaults setObject:latitude forKey:LATITUDE];
    
    // if the user is a cleaner then save his or her location in firebase
    if([defaults objectForKey:CLEANER_INFO] != nil){
       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *cleanerUID = [defaults objectForKey:UID];
            Firebase *fireBase = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
            Firebase *cleanerBase = [fireBase childByAppendingPath:[NSString stringWithFormat:@"cleaners/%@",cleanerUID]];
            NSDictionary *locationData = @{LONGITUDE:longitude,
                                           LATITUDE:latitude
                                           };
            [cleanerBase updateChildValues:locationData];
       });
    }
}

-(void)decrementUnreadMessagesNumberBy:(NSInteger)val{
    if(val <= _currentInstallation.badge)
        [self setParseBadgeNumber:_currentInstallation.badge - val];
}

-(void)setBadgeNumber:(NSInteger)number
{
    [self setParseBadgeNumber:number];
    [self updateNotificationNumberToChatViewController];
}

-(void)setParseBadgeNumber:(NSInteger)number
{
    //PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    _currentInstallation.badge = number;
    [_currentInstallation saveEventually];
}

-(void)updateNotificationNumberToChatViewController{
    if(_currentInstallation.badge > 0){
        [[self.chatViewController dc_tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d",_currentInstallation.badge]];
    }else{
        [[self.chatViewController dc_tabBarItem] setBadgeValue:[NSString stringWithFormat:@""]];
    }
}

@end
