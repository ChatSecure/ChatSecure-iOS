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
@import JSQMessagesViewController;
@import YapDatabase;
@import OTRKit;
#import "OTRDatabaseManager.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

@implementation OTRMediaItem
@synthesize mimeType = _mimeType;

- (instancetype) initWithFilename:(NSString *)filename mimeType:(NSString*)mimeType isIncoming:(BOOL)isIncoming {
    if (self = [super init]) {
        _filename = [filename copy];
        _isIncoming = isIncoming;
        _transferProgress = 0.0f;
        if (!mimeType) {
            _mimeType = OTRKitGetMimeTypeForExtension(filename.pathExtension);
        } else {
            _mimeType = [mimeType copy];
        }
    }
    return self;
}

/** Returns the appropriate subclass (OTRImageItem, etc) for incoming file */
+ (instancetype) incomingItemWithFilename:(NSString*)filename
                                 mimeType:(nullable NSString*)mimeType {
    if (!mimeType) {
        mimeType = OTRKitGetMimeTypeForExtension(filename.pathExtension);
    }
    NSRange imageRange = [mimeType rangeOfString:@"image"];
    NSRange audioRange = [mimeType rangeOfString:@"audio"];
    NSRange videoRange = [mimeType rangeOfString:@"video"];
    
    OTRMediaItem *mediaItem = nil;
    Class mediaClass = nil;
    if(audioRange.location == 0) {
        mediaClass = [OTRAudioItem class];
    } else if (imageRange.location == 0) {
        mediaClass = [OTRImageItem class];
    } else if (videoRange.location == 0) {
        mediaClass = [OTRVideoItem class];
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
        return OTRKitGetMimeTypeForExtension(self.filename.pathExtension);
    }
}

- (void)touchParentMessageWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameMessageMediaEdgeName];
    [[transaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:self.uniqueId collection:[[self class] collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [transaction touchObjectForKey:edge.sourceKey inCollection:edge.sourceCollection];
    }];
}

- (void)touchParentMessage
{
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self touchParentMessageWithTransaction:transaction];
    }];
}

- (OTRBaseMessage *)parentMessageInTransaction:(YapDatabaseReadTransaction *)readTransaction
{
    __block OTRBaseMessage *message = nil;
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
    UIImage *image = [OTRImages imageWithIdentifier:self.uniqueId];
    if (image) {
        CGSize size = [self mediaViewDisplaySize];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(0, 0, size.width, size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:imageView isOutgoing:!self.isIncoming];
        return imageView;
    }
    return nil;
}

- (CGSize)mediaViewDisplaySize
{
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
    OTRBaseMessage *message = [self parentMessageInTransaction:transaction];
    id<OTRThreadOwner> threadOwner = [message threadOwnerWithTransaction:transaction];
    NSString *buddyUniqueId = [threadOwner threadIdentifier];
    if (!buddyUniqueId) {
        return nil;
    }
    NSURL *url = [[OTRMediaServer sharedInstance] urlForMediaItem:self buddyUniqueId:buddyUniqueId];
    return url;
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
