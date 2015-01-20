//
//  OTRMediaItem.h
//  ChatSecure
//
//  Created by David Chiles on 1/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "JSQMessageMediaData.h"
#import "MTLModel+NSCoding.h"

typedef NS_ENUM(NSUInteger, OTRMediaItemType) {
    OTRMediaItemTypeUnkown = 0,
    OTRMediaItemTypeImage  = 1,
    OTRMediaItemTypeVideo  = 2,
    OTRMediaItemTypeAudio  = 3
};

@interface OTRMediaItem : MTLModel <JSQMessageMediaData>

@property (nonatomic, strong) NSString *filename;
@property (nonatomic) BOOL isIncoming;
@property (nonatomic) OTRMediaItemType mediaType;

@end
