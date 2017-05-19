//
//  OTRMediaItem.h
//  ChatSecure
//
//  Created by David Chiles on 1/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import JSQMessagesViewController;
#import "OTRYapDatabaseObject.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"

NS_ASSUME_NONNULL_BEGIN
@interface OTRMediaItem : OTRYapDatabaseObject <JSQMessageMediaData>

@property (nonatomic, readonly) NSString *mimeType;
@property (nonatomic, readonly) NSString *filename;
@property (nonatomic, readonly) BOOL isIncoming;

/** Valid 1 >= 0 */
@property (nonatomic, readwrite) float transferProgress;

/** If mimeType is not provided, it will be guessed from filename */
- (instancetype) initWithFilename:(NSString*)filename
                         mimeType:(nullable NSString*)mimeType
                       isIncoming:(BOOL)isIncoming NS_DESIGNATED_INITIALIZER;

/** Returns the appropriate subclass (OTRImageItem, etc) for incoming file. Only image/audio/video supported at the moment. */
+ (instancetype) incomingItemWithFilename:(NSString*)filename
                                 mimeType:(nullable NSString*)mimeType;

- (instancetype) init NS_UNAVAILABLE;

- (void)touchParentMessage DEPRECATED_MSG_ATTRIBUTE("Use touchParentMessageWithTransaction: instead.");
- (void)touchParentMessageWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;
- (nullable OTRBaseMessage *)parentMessageInTransaction:(YapDatabaseReadTransaction *)readTransaction;

+ (CGSize)normalizeWidth:(CGFloat)width height:(CGFloat)height;

- (nullable NSURL*) mediaServerURLWithTransaction:(YapDatabaseReadTransaction*)transaction;

@end
NS_ASSUME_NONNULL_END
