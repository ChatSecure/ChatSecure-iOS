//
//  OTRMediaItem.h
//  ChatSecure
//
//  Created by David Chiles on 1/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "JSQMessageMediaData.h"
#import "MTLModel+NSCoding.h"

@interface OTRMediaItem : MTLModel <JSQMessageMediaData>

@property (nonatomic, strong) NSString *filename;
@property (nonatomic) BOOL isIncoming;

+ (CGSize)normalizeWidth:(CGFloat)width height:(CGFloat)height;

@end
