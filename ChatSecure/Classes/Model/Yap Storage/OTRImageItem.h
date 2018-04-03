//
//  OTRImageItem.h
//  ChatSecure
//
//  Created by David Chiles on 1/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMediaItem.h"

NS_ASSUME_NONNULL_BEGIN
@interface OTRImageItem : OTRMediaItem

@property (nonatomic, readwrite) CGSize size;

/** If mimeType is not provided, it will be guessed from filename */
- (instancetype) initWithFilename:(NSString*)filename
                             size:(CGSize)size
                         mimeType:(nullable NSString*)mimeType
                       isIncoming:(BOOL)isIncoming NS_DESIGNATED_INITIALIZER;

- (instancetype) initWithFilename:(NSString*)filename
                         mimeType:(nullable NSString*)mimeType
                       isIncoming:(BOOL)isIncoming NS_UNAVAILABLE;

@end
NS_ASSUME_NONNULL_END
