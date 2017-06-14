//
//  OTRImageItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRImageItem.h"
#import "OTRImages.h"
#import "OTRMediaFileManager.h"
@import JSQMessagesViewController;
#import "OTRDatabaseManager.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRLog.h"
#import "OTRMediaItem+Private.h"

@interface OTRImageItem()
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat height;
@end

@implementation OTRImageItem

- (instancetype) initWithFilename:(NSString *)filename size:(CGSize)size mimeType:(NSString *)mimeType isIncoming:(BOOL)isIncoming {
    if (self = [super initWithFilename:filename mimeType:mimeType isIncoming:isIncoming]) {
        self.size = size;
    }
    return self;
}

- (CGSize)mediaViewDisplaySize
{
    if (self.height && self.width) {
        return [[self class] normalizeWidth:self.width height:self.height];
    }
    return [super mediaViewDisplaySize];
}

- (CGSize) size {
    return CGSizeMake(_width, _height);
}

- (void) setSize:(CGSize)size {
    _width = size.width;
    _height = size.height;
}

- (UIView *)mediaView {
    UIView *errorView = [self errorView];
    if (errorView) { return errorView; }
    UIImage *image = [OTRImages imageWithIdentifier:self.uniqueId];
    if (!image) {
        [self fetchMediaData];
        return nil;
    }
    CGSize size = [self mediaViewDisplaySize];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(0, 0, size.width, size.height);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:imageView isOutgoing:!self.isIncoming];
    return imageView;
}

- (BOOL) shouldFetchMediaData {
    return ![OTRImages imageWithIdentifier:self.uniqueId];
}

- (BOOL) handleMediaData:(NSData *)mediaData message:(nonnull id<OTRMessageProtocol>)message {
    [super handleMediaData:mediaData message:message];
    UIImage *image = [UIImage imageWithData:mediaData];
    if (!image) {
        DDLogWarn(@"Media item data is not an image!");
        return NO;
    }
    [OTRImages setImage:image forIdentifier:self.uniqueId];
    return YES;
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
