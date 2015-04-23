//
//  CleanerProfileCell.h
//  DormCatChat
//
//  Created by Huang Jie on 1/24/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASStarRatingView.h"

@interface CleanerProfileCell : UITableViewCell
@property (nonatomic,strong) IBOutlet UIImageView *genderIcon;
@property (nonatomic,strong) IBOutlet UIImageView *profileImage;
@property (nonatomic,strong) IBOutlet UILabel *username;
@property (nonatomic,strong) IBOutlet UILabel *distance;
@property (nonatomic,strong) IBOutlet UILabel *details;
@property (nonatomic,strong) IBOutlet UILabel *priceLabel;
@property (retain, nonatomic) IBOutlet ASStarRatingView *staticStarRatingView;
@end
