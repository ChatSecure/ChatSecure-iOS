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
#import "OTRBaseMessage.h"

NS_ASSUME_NONNULL_BEGIN
@interface OTRMediaItem : OTRYapDatabaseObject <JSQMessageMediaData, OTRMessageChildProtocol, OTRChildObjectProtocol>

@property (nonatomic, readwrite) NSString *mimeType;
@property (nonatomic, readonly) NSString *filename;
@property (nonatomic, readonly) BOOL isIncoming;
/** Text to show in message preview such as "📷 Picture Message" */
@property (nonatomic, readonly) NSString *displayText;

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

+ (CGSize)normalizeWidth:(CGFloat)width height:(CGFloat)height;

- (nullable NSURL*) mediaServerURLWithTransaction:(YapDatabaseReadTransaction*)transaction;

/** Fetches existing media item. Returns nil if not found */
+ (nullable instancetype) mediaItemForMessage:(id<OTRMessageProtocol>)message transaction:(YapDatabaseReadTransaction*)transaction;

// MARK: - Media Fetching


/* Return NO if data is already cached to prevent refetch */
- (BOOL) shouldFetchMediaData;
/** Triggers a refretch of media data. This is called internally when mediaView is accessed. */
- (void) fetchMediaData;
/** Overrideable in subclasses. This is called after data is fetched from db in fetchMediaData, but before display. Return YES if successful or NO if there was an error. */
- (BOOL) handleMediaData:(NSData*)mediaData message:(id<OTRMessageProtocol>)message;

@end
NS_ASSUME_NONNULL_END
