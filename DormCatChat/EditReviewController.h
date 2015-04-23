//
//  AddReviewViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 2/7/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASStarRatingView.h"

@interface EditReviewController : UIViewController
@property (nonatomic,strong) IBOutlet ASStarRatingView *starRatingView;
@property (nonatomic,strong) IBOutlet UITextView *reviewInputView;
@property (nonatomic,strong) NSDictionary * reviewInfo;
@property (nonatomic,strong) NSString *cleanerUID;
@end
