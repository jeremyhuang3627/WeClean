//
//  LoginViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 1/27/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoginViewControllerDelegate <NSObject>

-(void)loginComplete;

@end

@interface LoginViewController : UIViewController
@property (nonatomic,strong) IBOutlet UIButton *loginBtn;
@property (nonatomic,strong) IBOutlet UIButton *cancelBtn;
@property (nonatomic,strong) IBOutlet UIImageView *loginImage;
@property (nonatomic,strong) id<LoginViewControllerDelegate> delegate;
-(IBAction)cancel;
-(IBAction)fbLogin;
@end
