//
//  Utility.m
//  DormCatChat
//
//  Created by Huang Jie on 3/18/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "Utility.h"
#import "Macro.h"

@implementation Utility
+(void)showMessage:(NSString *)alertText withTitle:(NSString *)alertTitle
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                    message:alertText
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

+(NSString *)friendlyDistance:(NSNumber *)number
{
    double kmPerMile = 1.609344;
    if(([number doubleValue]/1000)/kmPerMile > 1000){
        return [NSString stringWithFormat:@"very far"];
    }else{
        return [NSString stringWithFormat:@"%.0f mi.",([number doubleValue]/1000)/kmPerMile];
    }
}

+(void)addTitleLabelToNavigationItem:(UINavigationItem *)navigationItem withText:(NSString *)title
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:AVENIR_LIGHT size:20];
    label.textAlignment = NSTextAlignmentCenter;
    // ^-Use UITextAlignmentCenter for older SDKs.
    label.textColor = [UIColor whiteColor]; // change this color
    navigationItem.titleView = label;
    label.text = NSLocalizedString(title, @"");
    [label sizeToFit];
}

+(NSString *)stringFromDate:(NSDate *)date usingFormatString:(NSString *)formatString
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:formatString];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

// dateString must be in the format specified by DATE_FORMAT_STRING
+(NSDate *)dateFromString:(NSString *)dateString usingFormatString:(NSString *)formatString
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:formatString];
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}

+(NSString *)dateStringNowWithFormat:(NSString *)format
{
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    NSString *dateString = [dateFormatter stringFromDate:now];
    return dateString;
}

@end
