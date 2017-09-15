//
//  OTRMediaItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMediaItem.h"
#import "OTRImages.h"
#import "OTRFileItem.h"
#import "OTRLog.h"
#import "OTRTextItem.h"
#import "OTRHTMLItem.h"
@import JSQMessagesViewController;
@import YapDatabase;
@import OTRKit;
@import MobileCoreServices;
@import OTRAssets;
#import "OTRDatabaseManager.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

static NSString* GetExtensionForMimeType(NSString* mimeType) {
    NSCParameterAssert(mimeType.length > 0);
    if (!mimeType.length) { return @""; }
    NSString *extension = @"";
    CFStringRef cfMimeType = (__bridge CFStringRef)mimeType;
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, cfMimeType, NULL);
    if (uti) {
        extension = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension));
        CFRelease(uti);
    }
    return extension;
}


@implementation OTRMediaItem
@synthesize mimeType = _mimeType;
@synthesize parentObjectKey = _parentObjectKey;
@synthesize parentObjectCollection = _parentObjectCollection;
@dynamic displayText;

- (instancetype) initWithFilename:(NSString *)filename mimeType:(NSString*)mimeType isIncoming:(BOOL)isIncoming {
    NSParameterAssert(filename);
    if (self = [super init]) {
        if (!filename.length) {
            filename = @"file";
        }
        _filename = [filename copy];
        _isIncoming = isIncoming;
        _transferProgress = 0.0f;
        if (!mimeType.length) {
            _mimeType = [self.class mimeTypeForFilename:filename];
        } else {
            NSString *extension = GetExtensionForMimeType(mimeType);
            if (![filename.pathExtension isEqualToString:extension]) {
                DDLogWarn(@"Given file extension does not match expected extension from mime type: %@ %@", filename.pathExtension, extension);
                if (!filename.pathExtension.length && extension.length > 0) {
                    _filename = [filename stringByAppendingPathExtension:extension];
                    DDLogInfo(@"Created new filename with best guess for file extension: %@", _filename);
                }
            }
            _mimeType = [mimeType copy];
        }
    }
    return self;
}

+ (NSString*) mimeTypeForFilename:(NSString*)filename {
    // This is to handle the case where we're storing temporary items with the full URL as the filename
    NSURL *url = [NSURL URLWithString:filename];
    NSString *pathExtension = filename.pathExtension;
    if (url) {
        pathExtension = url.pathExtension;
    }
    if (!pathExtension) {
        pathExtension = @"";
    }
    NSString *mimeType = OTRKitGetMimeTypeForExtension(pathExtension);
    return mimeType;
}

/** Returns the appropriate subclass (OTRImageItem, etc) for incoming file */
+ (instancetype) incomingItemWithFilename:(NSString*)filename
                                 mimeType:(nullable NSString*)mimeType {
    if (!mimeType) {
        mimeType = [self mimeTypeForFilename:filename];
    }
    NSRange imageRange = [mimeType rangeOfString:@"image"];
    NSRange audioRange = [mimeType rangeOfString:@"audio"];
    NSRange videoRange = [mimeType rangeOfString:@"video"];
    NSRange htmlRange = [mimeType rangeOfString:@"text/html"];
    NSRange textRange = [mimeType rangeOfString:@"text"];
    
    OTRMediaItem *mediaItem = nil;
    Class mediaClass = nil;
    if(audioRange.location == 0) {
        mediaClass = [OTRAudioItem class];
    } else if (imageRange.location == 0) {
        mediaClass = [OTRImageItem class];
    } else if (videoRange.location == 0) {
        mediaClass = [OTRVideoItem class];
    } else if (textRange.location == 0) {
        if (htmlRange.location == 0) {
            mediaClass = [OTRHTMLItem class];
        } else {
            mediaClass = [OTRTextItem class];
        }
    } else {
        mediaClass = [OTRFileItem class];
    }
    
    if (mediaClass) {
        mediaItem = [[mediaClass alloc] initWithFilename:filename mimeType:mimeType isIncoming:YES];
    }
    return mediaItem;
}

- (NSString*) mimeType {
    if (_mimeType) {
        return _mimeType;
    } else {
        return [self.class mimeTypeForFilename:self.filename];
    }
}

- (void)touchParentMessageWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [self touchParentObjectWithTransaction:transaction];
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameMessageMediaEdgeName];
    [[transaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:self.uniqueId collection:[[self class] collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [transaction touchObjectForKey:edge.sourceKey inCollection:edge.sourceCollection];
    }];
}

- (nullable id) parentObjectWithTransaction:(YapDatabaseReadTransaction*)transaction {
    if (!self.parentObjectKey || !self.parentObjectCollection) {
        return nil;
    }
    id parent = [transaction objectForKey:self.parentObjectKey inCollection:self.parentObjectCollection];
    return parent;
}

- (void) touchParentObjectWithTransaction:(YapDatabaseReadWriteTransaction *)transaction {
    if (!self.parentObjectKey || !self.parentObjectCollection) {
        return;
    }
    [transaction touchObjectForKey:self.parentObjectKey inCollection:self.parentObjectCollection];
}

- (id<OTRMessageProtocol>)parentMessageWithTransaction:(YapDatabaseReadTransaction *)readTransaction
{
    id parent = [self parentObjectWithTransaction:readTransaction];
    if (parent && [parent conformsToProtocol:@protocol(OTRMessageProtocol)]) {
        return parent;
    }
    __block id<OTRMessageProtocol> message = nil;
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameMessageMediaEdgeName];
    [[readTransaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:self.uniqueId collection:[[self class] collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        message = [OTRBaseMessage fetchObjectWithUniqueID:edge.sourceKey transaction:readTransaction];
        *stop = YES;
    }];
    return message;
}

#pragma - mark JSQMessageMediaData Methods

- (NSUInteger)mediaHash
{
    return [self hash];
}

- (UIView *)mediaView
{
    [self fetchMediaData];
    UIView *errorView = [self errorView];
    if (errorView) { return errorView; }
    return nil;
}

- (CGSize)mediaViewDisplaySize
{
    // This is an absolutely terrible way of doing this
    if ([self downloadMessage].messageError) {
        return CGSizeMake(210.0f, 100.0f);
    }
    //Taken from JSQMediaItem Example project
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return CGSizeMake(315.0f, 225.0f);
    }
    return CGSizeMake(210.0f, 150.0f);
}

- (UIView *)mediaPlaceholderView
{
    CGSize size = [self mediaViewDisplaySize];
    UIView *view = [JSQMessagesMediaPlaceholderView viewWithActivityIndicator];
    view.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
    [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:view isOutgoing:!self.isIncoming];
    return view;
}

- (NSUInteger)hash
{
    return self.filename.hash;
}

- (nullable NSURL*) mediaServerURLWithTransaction:(YapDatabaseReadTransaction*)transaction {
    id<OTRMessageProtocol> message = [self parentMessageWithTransaction:transaction];
    id<OTRThreadOwner> threadOwner = [message threadOwnerWithTransaction:transaction];
    NSString *buddyUniqueId = [threadOwner threadIdentifier];
    if (!buddyUniqueId) {
        return nil;
    }
    NSURL *url = [[OTRMediaServer sharedInstance] urlForMediaItem:self buddyUniqueId:buddyUniqueId];
    return url;
}

+ (nullable instancetype) mediaItemForMessage:(id<OTRMessageProtocol>)message transaction:(YapDatabaseReadTransaction*)transaction {
    if (!message.messageMediaItemKey.length) {
        return nil;
    }
    OTRMediaItem *item = [OTRMediaItem fetchObjectWithUniqueID:message.messageMediaItemKey transaction:transaction];
    return item;
}

- (BOOL) shouldFetchMediaData {
    return YES;
}

- (void) fetchMediaData {
    if (![self shouldFetchMediaData]) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // The superview should handle creating the actual imageview
        // this code is used to fetch the image from the data store and then cache in ram
        __block id<OTRThreadOwner> thread = nil;
        __block id<OTRMessageProtocol> message = nil;
        [OTRDatabaseManager.shared.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            message = [self parentMessageWithTransaction:transaction];
            thread = [message threadOwnerWithTransaction:transaction];
        }];
        if (!message || !thread) {
            DDLogError(@"Missing parent message or thread for media message!");
            return;
        }
        NSError *error = nil;
        NSData *data = [OTRMediaFileManager.shared dataForItem:self buddyUniqueId:thread.threadIdentifier error:&error];
        if(!data.length) {
            DDLogWarn(@"No data found for media item: %@", error);
            return;
        }
        BOOL result = [self handleMediaData:data message:message];
        if (!result) {
            DDLogError(@"Could not handle display for media item %@", self);
            return;
        }
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [self touchParentMessageWithTransaction:transaction];
        }];
    });
}

/** Overrideable in subclasses. This is called after data is fetched from db, but before display */
- (BOOL) handleMediaData:(NSData*)mediaData message:(id<OTRMessageProtocol>)message {
    NSParameterAssert(mediaData.length > 0);
    if (!mediaData.length) { return NO; }
    return NO;
}

/** ⚠️ Do not call from within an existing database transaction */
- (nullable OTRDownloadMessage*) downloadMessage {
    __block id<OTRMessageProtocol> message = nil;
    [OTRDatabaseManager.shared.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        message = [self parentMessageWithTransaction:transaction];
    }];
    if ([message isKindOfClass:[OTRDownloadMessage class]]) {
        return (OTRDownloadMessage*)message;
    }
    return nil;
}

- (UIView*) errorView {
    OTRDownloadMessage *message = [self downloadMessage];
    if (message.messageError) {
        MediaDownloadView *downloadView = [MediaDownloadView otr_viewFromNib];
        if (!downloadView) {
            return nil;
        }
        [downloadView setMediaItem:self message:(OTRDownloadMessage*)message];
        downloadView.backgroundColor = [UIColor jsq_messageBubbleLightGrayColor];
        CGSize size = [self mediaViewDisplaySize];
        downloadView.frame = CGRectMake(0, 0, size.width, size.height);
        [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:downloadView isOutgoing:!self.isIncoming];
        return downloadView;
    }
    return nil;
}

- (NSString*) displayText {
    NSString *item = [NSString stringWithFormat:@"📁 %@", FILE_MESSAGE_STRING()];
    if ([self isKindOfClass:[OTRImageItem class]]) {
        item = [NSString stringWithFormat:@"📷 %@", PICTURE_MESSAGE_STRING()];
    } else if ([self isKindOfClass:[OTRVideoItem class]]) {
        item = [NSString stringWithFormat:@"🎥 %@", VIDEO_MESSAGE_STRING()];
    } else if ([self isKindOfClass:[OTRAudioItem class]]) {
        item = [NSString stringWithFormat:@"🔊 %@", AUDIO_MESSAGE_STRING()];
    } else {
        NSURL *url = [NSURL URLWithString:self.filename];
        if (url) {
            item = [NSString stringWithFormat:@"🔗 %@", url.absoluteString];
        }
    }
    return item;
}

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    NSMutableDictionary *behaviors = [NSMutableDictionary dictionaryWithDictionary:[super encodingBehaviorsByPropertyKey]];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:NSStringFromSelector(@selector(displayText))];
    return behaviors;
}


#pragma - mark YapDatabaseRelationshipNode Methods

- (id)yapDatabaseRelationshipEdgeDeleted:(YapDatabaseRelationshipEdge *)edge withReason:(YDB_NotifyReason)reason
{
    //TODO:Delete File because the parent OTRMessage was deleted
    return nil;
}

#pragma - mark Class Methods

+ (CGSize)normalizeWidth:(CGFloat)width height:(CGFloat)height
{
    CGFloat maxWidth = 210;
    CGFloat maxHeight = 150;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        maxWidth = 315;
        maxHeight = 225;
    }
    
    float aspectRatio = width / height;
    
    if (aspectRatio < 1) {
        //Taller then wider then use max height and resize width
        CGFloat newWidth = maxHeight * aspectRatio;
        return CGSizeMake(newWidth, maxHeight);
    }
    else {
        //Wider than taller then use max width and resize height
        CGFloat newHeight = maxWidth * 1/aspectRatio;
        return CGSizeMake(maxWidth, newHeight);
    }
}

@end
