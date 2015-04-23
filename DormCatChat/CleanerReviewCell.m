//
//  CleanerReviewCell.m
//  DormCatChat
//
//  Created by Huang Jie on 1/25/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "CleanerReviewCell.h"

@implementation CleanerReviewCell

- (void)awakeFromNib {
    // Initialization code
    self.review.editable = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
