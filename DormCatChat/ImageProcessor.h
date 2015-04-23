//
//  ImageProcessor.h
//  DormCatChat
//
//  Created by Huang Jie on 1/20/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageProcessor : NSObject
+(UIImage*)roundCorneredImage:(UIImage*)orig radius:(CGFloat)r;
+(UIImage*)imageFromURL:(NSString *)url;
+(UIImage*)imageFromURLOrCache:(NSString *)urlString;
@end
