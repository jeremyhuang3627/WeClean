//
//  CleanerProfileCell.m
//  DormCatChat
//
//  Created by Huang Jie on 1/24/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "CleanerProfileCell.h"
#import "ImageProcessor.h"
#import "Macro.h"

@implementation CleanerProfileCell

- (void)awakeFromNib {
    // Initialization code
    self.priceLabel.backgroundColor = UIColorFromRGB(FLAT_BLUE);
   //self.priceLabel.highlightedTextColor = UIColorFromRGB(FLAT_BLUE);
    self.priceLabel.textColor = [UIColor whiteColor];
    self.priceLabel.layer.cornerRadius = 5;
    self.priceLabel.layer.masksToBounds = YES;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    UIColor *backgroundColor = self.priceLabel.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    self.priceLabel.backgroundColor = backgroundColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    UIColor *backgroundColor = self.priceLabel.backgroundColor;
    [super setSelected:selected animated:animated];
    self.priceLabel.backgroundColor = backgroundColor;
}

@end
