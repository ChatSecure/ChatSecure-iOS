//
//  OTRChatBubbleView.m
//  Off the Record
//
//  Created by David Chiles on 1/9/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRChatBubbleView.h"
#import "OTRConstants.h"

#import "OTRMessageTableViewCell.h"

@implementation OTRChatBubbleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.messageTextLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
#warning The line below throws a silent exception on iOS 6.
        //self.messageTextLabel.textAlignment = NSTextAlignmentNatural;
        self.messageBackgroundImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"MessageBubbleBlue"] stretchableImageWithLeftCapWidth:23 topCapHeight:15]];
        self.messageBackgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.deliveredImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.deliveredImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:self.deliveredImageView];
        [self addSubview:self.messageBackgroundImageView];
        [self addSubview:self.messageTextLabel];
        
        [self needsUpdateConstraints];
    }
    return self;
}

- (void)setIsDelivered:(BOOL)isDelivered
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isDelivered))];
    _isDelivered = isDelivered;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isDelivered))];
    
    if (self.isDelivered) {
        self.deliveredImageView.image = [UIImage imageNamed:@"checkmark"];
    }
    else {
        self.deliveredImageView.image = nil;
    }
    [self setNeedsUpdateConstraints];
}


- (void)setIsDelivered:(BOOL)isDelivered animated:(BOOL)animated
{
    NSTimeInterval duration = 0;
    if (animated) {
        duration = .5;
    }
    [UIView animateWithDuration:duration animations:^{
        [self setIsDelivered:isDelivered];
        [self layoutIfNeeded];
    }];
}

- (void)setIsIncoming:(BOOL)isIncoming
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isIncoming))];
    _isIncoming = isIncoming;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isIncoming))];
    if (_isIncoming) {
        self.messageBackgroundImageView.image = [[UIImage imageNamed:@"MessageBubbleGray"]stretchableImageWithLeftCapWidth:23 topCapHeight:15];
    }
    else {
        self.messageBackgroundImageView.image = [[UIImage imageNamed:@"MessageBubbleBlue"]stretchableImageWithLeftCapWidth:15 topCapHeight:15];
    }
    [self setNeedsUpdateConstraints];
}

- (void)setMessageTextLabel:(TTTAttributedLabel *)messageTextLabel
{
    [_messageTextLabel removeFromSuperview];
    [self willChangeValueForKey:NSStringFromSelector(@selector(messageTextLabel))];
    _messageTextLabel = messageTextLabel;
    [self didChangeValueForKey:NSStringFromSelector(@selector(messageTextLabel))];
    _messageTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_messageTextLabel];
    [self setNeedsUpdateConstraints];
}

- (void)setupConstraints {
    //Delivered Image View
    
    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.deliveredImageView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.deliveredImageView
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1.0
                                               constant:10];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.deliveredImageView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1.0
                                               constant:10];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.messageBackgroundImageView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.messageTextLabel
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:1.0
                                               constant:34];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.messageBackgroundImageView
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.messageTextLabel
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:1.0
                                               constant:13];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.messageBackgroundImageView
                                              attribute:NSLayoutAttributeCenterY
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeCenterY
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    //Text Label
    constraint = [NSLayoutConstraint constraintWithItem:self.messageTextLabel
                                              attribute:NSLayoutAttributeCenterY
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.messageBackgroundImageView
                                              attribute:NSLayoutAttributeCenterY
                                             multiplier:1.0
                                               constant:-2.0];
    [self addConstraint:constraint];
    
    
    
    
    
    //self
    constraint = [NSLayoutConstraint constraintWithItem:self
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.messageBackgroundImageView
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
}

-(void) updateConstraints
{
    [super updateConstraints];
    
    [self setupConstraints];
    
    CGSize messageTextLabelSize = [self.messageTextLabel sizeThatFits:CGSizeMake(180, CGFLOAT_MAX)];
    [self removeConstraint:textWidthConstraint];
    textWidthConstraint = [NSLayoutConstraint constraintWithItem:self.messageTextLabel
                                                       attribute:NSLayoutAttributeWidth
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:nil
                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                      multiplier:1.0
                                                        constant:messageTextLabelSize.width];
    [self addConstraint:textWidthConstraint];
    
    [self removeConstraint:textHeightConstraint];
    textHeightConstraint = [NSLayoutConstraint constraintWithItem:self.messageTextLabel
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1.0
                                                         constant:messageTextLabelSize.height];
    [self addConstraint:textHeightConstraint];
    
    [self removeConstraint:labelSideConstraint];
    [self removeConstraint:imageViewSideConstraint];
    [self removeConstraint:deliveredSideConstraint];
    if (self.isIncoming) {
        labelSideConstraint = [NSLayoutConstraint constraintWithItem:self.messageTextLabel
                                                  attribute:NSLayoutAttributeRight
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.messageBackgroundImageView
                                                  attribute:NSLayoutAttributeRight
                                                 multiplier:1.0
                                                   constant:-12.0];
     
        imageViewSideConstraint = [NSLayoutConstraint constraintWithItem:self.messageBackgroundImageView
                                                  attribute:NSLayoutAttributeLeft
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self
                                                  attribute:NSLayoutAttributeLeft
                                                 multiplier:1.0
                                                constant:0.0];
        
        deliveredSideConstraint = [NSLayoutConstraint constraintWithItem:self.deliveredImageView
                                                               attribute:NSLayoutAttributeLeft
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.messageBackgroundImageView
                                                               attribute:NSLayoutAttributeRight
                                                              multiplier:1.0
                                                                constant:5.0];
    }
    else {
        labelSideConstraint = [NSLayoutConstraint constraintWithItem:self.messageTextLabel
                                                  attribute:NSLayoutAttributeLeft
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.messageBackgroundImageView
                                                  attribute:NSLayoutAttributeLeft
                                                 multiplier:1.0
                                                   constant:12.0];

        imageViewSideConstraint = [NSLayoutConstraint constraintWithItem:self.messageBackgroundImageView
                                                  attribute:NSLayoutAttributeRight
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self
                                                  attribute:NSLayoutAttributeRight
                                                 multiplier:1.0
                                                   constant:0.0];
        
        deliveredSideConstraint = [NSLayoutConstraint constraintWithItem:self.deliveredImageView
                                                               attribute:NSLayoutAttributeRight
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.messageBackgroundImageView
                                                               attribute:NSLayoutAttributeLeft
                                                              multiplier:1.0
                                                                constant:-5.0];
    }
    [self addConstraint:deliveredSideConstraint];
    [self addConstraint:imageViewSideConstraint];
    [self addConstraint:labelSideConstraint];
}

@end
