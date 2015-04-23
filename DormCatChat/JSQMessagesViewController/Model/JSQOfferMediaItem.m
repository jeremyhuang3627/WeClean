//
//  JSQOfferMediaItem.m
//  WeClean
//
//  Created by Huang Jie on 4/10/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "JSQOfferMediaItem.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

@implementation JSQOfferMediaItem

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView
{
    if(self.offerViewCache == nil){
        CGSize size = [self mediaViewDisplaySize];
        JSQOfferView *view = [JSQOfferView new];
        view.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
        view.contentMode = UIViewContentModeScaleAspectFill;
        view.clipsToBounds = YES;
        view.backgroundColor = [UIColor whiteColor];
        [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:view isOutgoing:YES];
        self.offerViewCache = view;
    }
    return self.offerViewCache;
}

- (NSUInteger)mediaHash
{
    return self.hash;
}


@end
