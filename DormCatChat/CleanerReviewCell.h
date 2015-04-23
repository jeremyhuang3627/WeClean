//
//  CleanerReviewCell.h
//  DormCatChat
//
//  Created by Huang Jie on 1/25/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASStarRatingView.h"

@interface CleanerReviewCell : UITableViewCell
@property (nonatomic,strong) IBOutlet UILabel *username;
@property (nonatomic,strong) IBOutlet UITextView *review;
@property (retain, nonatomic) IBOutlet ASStarRatingView *staticStarRatingView;
@property (nonatomic,strong) IBOutlet UIImageView *userimage;
@end
