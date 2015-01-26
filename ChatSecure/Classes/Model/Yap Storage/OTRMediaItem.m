//
//  OTRMediaItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMediaItem.h"
#import "OTRImages.h"
#import "JSQMessagesMediaPlaceholderView.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

@implementation OTRMediaItem

- (NSString *)mediaPath
{
    // Example file storage in documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:self.filename];
}

#pragma - mark JSQMessageMediaData Methods

- (UIView *)mediaView
{
    // Naive fetching from unencrypted file storage with no caching
    CGSize size = [self mediaViewDisplaySize];
    UIImage *image = [UIImage imageWithContentsOfFile:[self mediaPath]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:imageView isOutgoing:!self.isIncoming];
    return imageView;
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
    return [self mediaPath].hash;
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
        CGFloat newWidth = maxHeight * 1/aspectRatio;
        return CGSizeMake(newWidth, maxHeight);
    }
    else {
        //Wider than taller then use max width and resize height
        CGFloat newHeight = maxWidth * 1/aspectRatio;
        return CGSizeMake(maxWidth, newHeight);
    }
}

@end
