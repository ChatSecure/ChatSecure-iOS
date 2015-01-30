//
//  OTRAudioItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAudioItem.h"
#import "OTRAudioBubbleView.h"
#import "UIColor+JSQMessages.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

@implementation OTRAudioItem

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

- (CGSize)mediaViewDisplaySize
{
    return CGSizeMake(90, 38);
}

- (UIView *)mediaView
{
    CGSize size = [self mediaViewDisplaySize];
    UIEdgeInsets bubbleInset = UIEdgeInsetsMake(5, 5, 5, 8);
    CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
    CGRect bubbleRect = UIEdgeInsetsInsetRect(viewRect, bubbleInset);
    
    OTRAudioBubbleView *bubbleView = [[OTRAudioBubbleView alloc] initWithFrame:bubbleRect];
    NSUInteger minutes = (int)self.timeLength / 60;
    NSUInteger seconds = (int)self.timeLength % 60;
    
    bubbleView.timeLabel.text = [NSString stringWithFormat:@"%ld:%02ld",minutes,seconds];
    
    
    UIView *view = [[UIView alloc] initWithFrame:viewRect];
    [view addSubview:bubbleView];
    
    if (self.isIncoming) {
        view.backgroundColor = [UIColor jsq_messageBubbleLightGrayColor];
    }
    else {
        view.backgroundColor = [UIColor jsq_messageBubbleBlueColor];
    }
    
    [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:view isOutgoing:!self.isIncoming];
    
    return view;
}

@end
