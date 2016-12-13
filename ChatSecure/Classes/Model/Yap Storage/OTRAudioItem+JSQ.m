//
//  OTRAudioItem+JSQ.m
//  ChatSecure
//
//  Created by Chris Ballinger on 12/11/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRAudioItem+JSQ.h"
#import "OTRAudioControlsView.h"
@import JSQMessagesViewController;
#import "OTRPlayPauseProgressView.h"

@implementation OTRAudioItem (JSQ)

- (NSUInteger)mediaHash
{
    return [super hash];
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

- (CGSize)mediaViewDisplaySize
{
    return CGSizeMake(90, 38);
}

- (UIView *)mediaPlaceholderView
{
    return [super mediaPlaceholderView];
}

- (UIView *)mediaView
{
    CGSize size = [self mediaViewDisplaySize];
    UIEdgeInsets bubbleInset = UIEdgeInsetsMake(5, 5, 5, 5);
    if (self.isIncoming) {
        bubbleInset.left = 9;
    } else {
        bubbleInset.right = 8;
    }
    
    CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
    CGRect bubbleRect = UIEdgeInsetsInsetRect(viewRect, bubbleInset);
    
    OTRAudioControlsView *audioControls = [[OTRAudioControlsView alloc] initWithFrame:bubbleRect];
    [audioControls setTime:self.timeLength];
    
    
    UIView *view = [[UIView alloc] initWithFrame:viewRect];
    [view addSubview:audioControls];
    
    if (self.isIncoming) {
        view.backgroundColor = [UIColor jsq_messageBubbleLightGrayColor];
        audioControls.timeLabel.textColor = [UIColor blackColor];
        audioControls.playPuaseProgressView.color = [UIColor blackColor];
        
    }
    else {
        view.backgroundColor = [UIColor jsq_messageBubbleBlueColor];
        audioControls.timeLabel.textColor = [UIColor whiteColor];
        audioControls.playPuaseProgressView.color = [UIColor whiteColor];
    }
    
    [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:view isOutgoing:!self.isIncoming];
    
    return view;
}




@end
