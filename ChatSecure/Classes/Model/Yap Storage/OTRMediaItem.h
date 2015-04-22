//
//  OTRMediaItem.h
//  ChatSecure
//
//  Created by David Chiles on 1/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "JSQMessageMediaData.h"
#import "OTRYapDatabaseObject.h"

@class OTRMessage;

@interface OTRMediaItem : OTRYapDatabaseObject <JSQMessageMediaData>

@property (nonatomic, strong) NSString *filename;
@property (nonatomic) BOOL isIncoming;

@property (nonatomic) float transferProgress;

- (void)touchParentMessage;
- (void)touchParentMessageWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;
- (OTRMessage *)parentMessageInTransaction:(YapDatabaseReadTransaction *)readTransaction;

+ (CGSize)normalizeWidth:(CGFloat)width height:(CGFloat)height;

@end
