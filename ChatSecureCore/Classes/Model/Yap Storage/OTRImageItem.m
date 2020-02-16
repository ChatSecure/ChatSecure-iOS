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
#import "UIImage+ChatSecure.h"

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
    self.size = image.size;
    CGSize size = [self mediaViewDisplaySize];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:imageView isOutgoing:!self.isIncoming];

    NSString *thumbnailKey = [NSString stringWithFormat:@"%@-thumb", self.uniqueId];
    UIImage *imageThumb = [OTRImages imageWithIdentifier:thumbnailKey];
    if (!imageThumb) {
        __weak typeof(UIImageView *)weakImageView = imageView;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *resizedImage = [UIImage otr_imageWithImage:image scaledToSize:size];
            [OTRImages setImage:resizedImage forIdentifier:thumbnailKey];
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakImageView)strongImageView = weakImageView;
                [strongImageView setImage:resizedImage];
            });
        });
    } else {
        [imageView setImage:imageThumb];
    }
    return imageView;
}

- (BOOL) shouldFetchMediaData {
    return ![OTRImages imageWithIdentifier:self.uniqueId];
}

- (BOOL) handleMediaData:(NSData *)mediaData message:(nonnull id<OTRMessageProtocol>)message {
    [super handleMediaData:mediaData message:message];
    UIImage *image = [UIImage imageWithData:mediaData];
    if (!image) {
        DDLogError(@"Media item data is not an image!");
        return NO;
    }
    self.size = image.size;
    [OTRImages setImage:image forIdentifier:self.uniqueId];
    return YES;
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
