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
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRDatabaseManager.h"
#import "OTRMessage.h"
#import "UIImage+JSQMessages.h"
#import "PureLayout.h"

@import AVFoundation;

@implementation OTRVideoItem

- (NSURL *)mediaURL
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    NSString *path = [documentsPath stringByAppendingPathComponent:self.filename];
    return [NSURL fileURLWithPath:path];
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
            AVAsset *asset = [AVAsset assetWithURL:[strongSelf mediaURL]];
            AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
            NSError *error = nil;
            //Grab middle frame
            CMTime time = CMTimeMultiplyByFloat64(asset.duration, 0.5);
            CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            if (image && !error) {
                [OTRImages setImage:image forIdentifier:strongSelf.filename];
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

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
