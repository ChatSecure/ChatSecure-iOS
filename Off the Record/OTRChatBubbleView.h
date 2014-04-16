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

@property (nonatomic, strong) UIImageView *messageBackgroundImageView;
@property (nonatomic, strong) UIImageView *deliveredImageView;
@property (nonatomic, strong) UIImageView *secureImageView;
@property (nonatomic, strong, readonly) TTTAttributedLabel *messageTextLabel;
@property (nonatomic, getter = isIncoming) BOOL incoming;
@property (nonatomic, getter = isDelivierd) BOOL delivered;
@property (nonatomic, getter = isSecure) BOOL secure;

- (void)updateLayout;

+(TTTAttributedLabel *)defaultLabel;

@end
