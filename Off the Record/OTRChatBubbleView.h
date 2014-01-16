//
//  OTRChatBubbleView.h
//  Off the Record
//
//  Created by David Chiles on 1/9/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TTTAttributedLabel.h"

@interface OTRChatBubbleView : UIView
{
    NSLayoutConstraint * imageViewSideConstraint;
    NSLayoutConstraint * labelSideConstraint;
    NSLayoutConstraint * textWidthConstraint;
    NSLayoutConstraint * textHeightConstraint;
    NSLayoutConstraint * deliveredSideConstraint;
}

@property (nonatomic, strong) UIImageView * messageBackgroundImageView;
@property (nonatomic, strong) UIImageView * deliveredImageView;
@property (nonatomic, strong) TTTAttributedLabel * messageTextLabel;
@property (nonatomic) BOOL isIncoming;
@property (nonatomic) BOOL isDelivered;

- (void)setIsDelivered:(BOOL)isDelivered animated:(BOOL)animated;

@end
