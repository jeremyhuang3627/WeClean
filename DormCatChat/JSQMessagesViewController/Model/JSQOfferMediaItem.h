//
//  JSQOfferMediaItem.h
//  WeClean
//
//  Created by Huang Jie on 4/10/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "JSQMediaItem.h"
#import "JSQOfferView.h"

// JSQOfferMediaItem represents the offer gave by the customer for the cleaner

@interface JSQOfferMediaItem : JSQMediaItem <JSQMessageMediaData>

@property (strong,nonatomic) JSQOfferView * offerViewCache;

@end
