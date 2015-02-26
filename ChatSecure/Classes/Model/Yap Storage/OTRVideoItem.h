//
//  OTRVideoItem.h
//  ChatSecure
//
//  Created by David Chiles on 1/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMediaItem.h"

@interface OTRVideoItem : OTRMediaItem

@property (nonatomic) float width;
@property (nonatomic) float height;

+ (instancetype)videoItemWithFileURL:(NSURL *)url;

@end
