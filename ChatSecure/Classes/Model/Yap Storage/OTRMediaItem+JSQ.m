//
//  OTRMediaItem+JSQ.m
//  ChatSecure
//
//  Created by Chris Ballinger on 12/11/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//


#import "OTRMediaItem+JSQ.h"
#import "OTRImages.h"
#import "OTRYapDatabaseObject.h"

@implementation OTRMediaItem (JSQ)

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

@end
