//
//  ImageProcessor.m
//  DormCatChat
//
//  Created by Huang Jie on 1/20/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "ImageProcessor.h"
#import "AppDelegate.h"

@implementation ImageProcessor
+(UIImage*)roundCorneredImage: (UIImage*)orig radius:(CGFloat)r {
    UIGraphicsBeginImageContextWithOptions(orig.size, NO, 0);
    [[UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero, orig.size}
                                cornerRadius:r] addClip];
    [orig drawInRect:(CGRect){CGPointZero, orig.size}];
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

+(UIImage*)imageFromURL:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *img = [[UIImage alloc] initWithData:data];
    return img;
}

+(UIImage*)imageFromURLOrCache:(NSString *)urlString // this retrieves an image if it is already in global cache otherwise load the image from that url
{
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSCache * cache = appDelegate.globalImageCache;
    UIImage * img;
    if([cache objectForKey:urlString] != nil){
        img = [cache objectForKey:urlString];
    }else{
        img = [self imageFromURL:urlString];
        if(img != nil)
            [cache setObject:img forKey:urlString];
    }
    return img;
}

@end
