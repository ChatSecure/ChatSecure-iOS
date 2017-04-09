//
//  OTRVideoItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRVideoItem.h"
#import "OTRImages.h"
@import YapDatabase;
#import "OTRDatabaseManager.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
@import JSQMessagesViewController;
@import PureLayout;
#import "OTRMediaServer.h"

@import AVFoundation;

@interface OTRVideoItem()
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@end

@implementation OTRVideoItem

- (CGSize) size {
    return CGSizeMake(_width, _height);
}

- (void) setSize:(CGSize)size {
    _width = size.width;
    _height = size.height;
}

- (NSURL *)mediaURL
{
    __block NSString *buddyUniqueId = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRBaseMessage *message = [self parentMessageInTransaction:transaction];
        buddyUniqueId = message.buddyUniqueId;
    }];
    
    return [[OTRMediaServer sharedInstance] urlForMediaItem:self buddyUniqueId:buddyUniqueId];
}

- (CGSize)mediaViewDisplaySize
{
    if (self.height && self.width) {
        return [[self class] normalizeWidth:self.width height:self.height];
    }
    return [super mediaViewDisplaySize];
}

- (UIView *)mediaView
{
    UIView *view = [super mediaView];
    if (!view) {
        //async loading image into OTRImages image cache
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            AVURLAsset *asset = [AVURLAsset assetWithURL:[strongSelf mediaURL]];
            AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
            imageGenerator.appliesPreferredTrackTransform = YES;
            NSError *error = nil;
            //Grab middle frame
            CMTime time = CMTimeMultiplyByFloat64(asset.duration, 0.5);
            CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            if (image && !error) {
                [OTRImages setImage:image forIdentifier:strongSelf.uniqueId];
                [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                    [strongSelf touchParentMessageWithTransaction:transaction];
                }];
            }
        });
    } else {
        UIImage *playIcon = [[UIImage jsq_defaultPlayImage] jsq_imageMaskedWithColor:[UIColor lightGrayColor]];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:playIcon];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.clipsToBounds = YES;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [view addSubview:imageView];
        [imageView autoCenterInSuperview];
    }
    
    
    
    return view;
}

/** If mimeType is not provided, it will be guessed from filename */
- (instancetype) initWithVideoURL:(NSURL*)url
                       isIncoming:(BOOL)isIncoming {
    NSParameterAssert(url);
    if (self = [super initWithFilename:url.lastPathComponent mimeType:nil isIncoming:isIncoming]) {
        AVURLAsset *asset = [AVURLAsset assetWithURL:url];
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        CGSize videoSize = videoTrack.naturalSize;
        
        CGAffineTransform transform = videoTrack.preferredTransform;
        if ((videoSize.width == transform.tx && videoSize.height == transform.ty) || (transform.tx == 0 && transform.ty == 0))
        {
            _width = videoSize.width;
            _height = videoSize.height;
        }
        else
        {
            _width = videoSize.height;
            _height = videoSize.width;
        }
    }
    return self;
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
