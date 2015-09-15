//
//  OTRVideoItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRVideoItem.h"
#import "OTRImages.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"
@import YapDatabase;
#import "OTRDatabaseManager.h"
#import "OTRMessage.h"
#import "UIImage+JSQMessages.h"
#import "PureLayout.h"
#import "OTRMediaServer.h"

@import AVFoundation;

@implementation OTRVideoItem

- (NSURL *)mediaURL
{
    __block NSString *buddyUniqueId = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRMessage *message = [self parentMessageInTransaction:transaction];
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
                [strongSelf touchParentMessage];
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

+ (instancetype)videoItemWithFileURL:(NSURL *)url
{
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGSize videoSize = videoTrack.naturalSize;
    
    OTRVideoItem *videoItem = [[OTRVideoItem alloc] init];
    videoItem.filename = url.lastPathComponent;
    
    CGAffineTransform transform = videoTrack.preferredTransform;
    if ((videoSize.width == transform.tx && videoSize.height == transform.ty) || (transform.tx == 0 && transform.ty == 0))
    {
        videoItem.width = videoSize.width;
        videoItem.height = videoSize.height;
    }
    else
    {
        videoItem.width = videoSize.height;
        videoItem.height = videoSize.width;
    }
    
    return videoItem;
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
