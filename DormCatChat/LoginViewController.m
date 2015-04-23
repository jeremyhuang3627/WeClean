//
//  LoginViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 1/27/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "LoginViewController.h"
#import "Macro.h"
#import "ImageProcessor.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AppDelegate.h"
#import "AccountViewController.h"
#import <Firebase/Firebase.h>
#import <Parse/Parse.h>
#import "Utility.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = UIColorFromRGB(FLAT_GRAY);
    
    [self.loginImage setImage:[ImageProcessor roundCorneredImage:[UIImage imageNamed:@"icon@120x120.png"] radius:10]];
    [self addShadow:self.loginImage];
    
    [self styleBtn:self.loginBtn];
    //[self.loginBtn.titleLabel setText:@"Facebook Login"];
    [self styleBtn:self.cancelBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)styleBtn:(UIButton *)btn
{
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = UIColorFromRGB(FLAT_GREEN);
    btn.layer.cornerRadius = 10;
    btn.layer.masksToBounds = YES;
    btn.titleLabel.font = [UIFont fontWithName:AVENIR_LIGHT size:15];
    [self addShadow:btn];
}

-(void)addShadow:(UIView *)view
{
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.2;
    view.layer.shadowRadius = 5;
    view.layer.shadowOffset = CGSizeMake(5, 5);
    [view setClipsToBounds:NO];
}

-(IBAction)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)fbLogin
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // If the session state is any of the two "open" states when the button is clicked
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [FBSession.activeSession closeAndClearTokenInformation];
        
        // If the session state is not any of the two "open" states when the button is clicked
    } else {
        // Open a session showing the user the login UI
        // You must ALWAYS ask for public_profile permissions when opening a session
        Firebase *firebase = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile",@"email"]
                                           allowLoginUI:YES
                                      completionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             if (error) {
                 NSLog(@"Facebook login failed. Error: %@", error);
             } else if (state == FBSessionStateOpen) {
                 NSString *accessToken = session.accessTokenData.accessToken;
                 NSLog(@"session expiration date %@",[Utility stringFromDate:session.accessTokenData.expirationDate usingFormatString:DATE_FORMAT_STRING]);
                 
                 [firebase authWithOAuthProvider:@"facebook" token:accessToken
                             withCompletionBlock:^(NSError *error, FAuthData *authData) {
                                 if (error) {
                                     NSLog(@"Login failed. %@", error);
                                 } else {
                                     // if logged in try to retrieve user info from firebase otherwise use FAuthData
                                     Firebase *usersBase = [firebase childByAppendingPath:[NSString stringWithFormat:@"users/%@",authData.uid]];
                                     Firebase *cleanerBase = [firebase childByAppendingPath:[NSString stringWithFormat:@"cleaners/%@",authData.uid]];
                                     
                                     [usersBase observeSingleEventOfType:FEventTypeValue withBlock:
                                      ^(FDataSnapshot *userSnapshot){
                                          NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                          [cleanerBase observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *cleanerSnapshot){
                                              if([self checkValidSnapshot:userSnapshot withUID:authData.uid]){
                                                  // chekc if user is cleaner
                                                  if([cleanerSnapshot hasChild:authData.uid]){
                                                      [defaults setObject:cleanerSnapshot.value[authData.uid] forKey:CLEANER_INFO];
                                                  }
                                                  
                                                  [defaults setObject:userSnapshot.value[authData.uid] forKey:AUTH_DATA];
                                                  [defaults setObject:authData.uid forKey:UID];
                                              }else{
                                                  [defaults setObject:authData.providerData forKey:AUTH_DATA];
                                                  [defaults setObject:authData.uid forKey:UID];
                                                  [[usersBase childByAppendingPath:@"cachedUserProfile"] setValue:authData.providerData[@"cachedUserProfile"]];
                                              }
                                              
                                              PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                                              // save authData to Parse for target push notification.
                                              [currentInstallation setObject:authData.uid forKey:UID];
                                              [currentInstallation saveInBackground];
                                              
                                              // update the location of this user
                                              AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                                              [appDelegate updateLocation];
                                              
                                              [self cancel];
                                              if(self.delegate != nil){
                                                  [self.delegate loginComplete];
                                              }
                                          }];
                                      }];
                                 }
                             }];
             }
         }];
    }
    });
}


-(BOOL)checkValidSnapshot:(FDataSnapshot *)snapshot withUID:(NSString *)uid{
    //NSLog(@"snapshot %@",snapshot);
    if(![snapshot hasChild:uid]){
        return NO;
    }
    
    if(![snapshot.value isKindOfClass:[NSDictionary class]]){
        return NO;
    }
    
    if(!snapshot.value[uid]){
        return NO;
    }
    
    if(![snapshot.value[uid] isKindOfClass:[NSDictionary class]]){
        return NO;
    }
    
    if(![[snapshot.value[uid] allKeys] containsObject:@"cachedUserProfile"]){
        return NO;
    }
    
    return  YES;
}

@end
