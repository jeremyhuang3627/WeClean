//
//  JSQOfferView.m
//  WeClean
//
//  Created by Huang Jie on 4/10/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "JSQOfferView.h"
#import "Macro.h"

@implementation JSQOfferView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    //_customConstraints = [[NSMutableArray alloc] init];
    
    UIView *view = nil;
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"JSQOfferView"
                                                     owner:self
                                                   options:nil];
    for (id object in objects) {
        if ([object isKindOfClass:[UIView class]]) {
            view = object;
            break;
        }
    }
    
    if(view != nil){
//        CALayer* layer = [self.offerLabel layer];
//        UIColor * borderColor = UIColorFromRGB(FLAT_GRAY);
//        CALayer *bottomBorder = [CALayer layer];
//        bottomBorder.borderColor = borderColor.CGColor;
//        bottomBorder.borderWidth = 0.5;
//        bottomBorder.frame = CGRectMake(-1, layer.frame.size.height-1, layer.frame.size.width, 1);
//        [bottomBorder setBorderColor:borderColor.CGColor];
//        [layer addSublayer:bottomBorder];
        [self addSubview:view];
    }
}


@end
