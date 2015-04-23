//
//  Utility.h
//  DormCatChat
//
//  Created by Huang Jie on 3/18/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utility : NSObject
+(void)showMessage:(NSString *)alertText withTitle:(NSString *)alertTitle;
+(NSString *)friendlyDistance:(NSNumber *)number;
+(void)addTitleLabelToNavigationItem:(UINavigationItem *)navigationItem withText:(NSString *)title;
+(NSString *)stringFromDate:(NSDate *)date usingFormatString:(NSString *)formatString;
+(NSDate *)dateFromString:(NSString *)dateString usingFormatString:(NSString *)formatString;
+(NSString *)dateStringNowWithFormat:(NSString *)format;
@end
