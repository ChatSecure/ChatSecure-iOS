//
//  OTRHoldToTalkView.m
//  ChatSecure
//
//  Created by David Chiles on 4/1/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRHoldToTalkView.h"
#import "PureLayout.h"

@interface OTRHoldToTalkView ()

@property (nonatomic) BOOL addedConstraints;

@end

@implementation OTRHoldToTalkView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _textLabel = [[UILabel alloc] initForAutoLayout];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.multipleTouchEnabled = NO;
        
        [self addSubview:self.textLabel];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return [self.textLabel intrinsicContentSize];
}

- (void)updateConstraints
{
    if (!self.addedConstraints) {
        [self.textLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.textLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    }
    [super updateConstraints];
}

#pragma - mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.delegate didBeginTouch:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint pointInWindow = [[touches anyObject] locationInView:nil];
    if ([self.delegate respondsToSelector:@selector(view:touchDidMoveToPointInWindow:)]) {
        [self.delegate view:self touchDidMoveToPointInWindow:pointInWindow];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.delegate didReleaseTouch:self];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.delegate touchCancelled:self];
}


@end
