//
//  OTRHoldToTalkView.m
//  ChatSecure
//
//  Created by David Chiles on 4/1/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRHoldToTalkView.h"
#import "PureLayout.h"
#import "OTRTouchAndHoldGestureRecognizer.h"

@interface OTRHoldToTalkView ()

@property (nonatomic) BOOL addedConstraints;
@property (nonatomic, strong) OTRTouchAndHoldGestureRecognizer *gestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;


@end

@implementation OTRHoldToTalkView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _textLabel = [[UILabel alloc] initForAutoLayout];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.userInteractionEnabled = NO;
        self.multipleTouchEnabled = NO;
        
        self.gestureRecognizer = [[OTRTouchAndHoldGestureRecognizer alloc] initWithTarget:self action:@selector(gesture:)];
        [self addGestureRecognizer:self.gestureRecognizer];
        
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

- (void)gesture:(OTRTouchAndHoldGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            NSLog(@"Touch Began");
            [self.delegate didBeginTouch:self];
            break;
        }
        case UIGestureRecognizerStateChanged: {
             CGPoint pointInWindow = [self.gestureRecognizer locationInView:nil];
            [self.delegate view:self touchDidMoveToPointInWindow:pointInWindow];
            break;
        }
        case UIGestureRecognizerStateCancelled: {
           [self.delegate touchCancelled:self];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            [self.delegate didReleaseTouch:self];
            break;
        }
        default:
            break;
    }
}


@end
