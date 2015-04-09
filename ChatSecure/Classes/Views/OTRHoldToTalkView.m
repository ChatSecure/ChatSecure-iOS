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

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic) BOOL addedConstraints;

@end

@implementation OTRHoldToTalkView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.textLabel = [[UILabel alloc] initForAutoLayout];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        self.normalTextColor = [UIColor blackColor];
        self.normalBackgroundColor = [UIColor whiteColor];
        self.pressedTextColor = self.normalBackgroundColor;
        self.pressedBackgroundColor = self.normalTextColor;
        
        self.state = OTRHoldToTalkViewStateNormal;
        
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)setState:(OTRHoldToTalkViewState)state
{
    _state = state;
    if (state == OTRHoldToTalkViewStateNormal) {
        self.textLabel.textColor = self.normalTextColor;
        self.backgroundColor = self.normalBackgroundColor;
        self.textLabel.text = self.normalText;
    }
    else {
        self.textLabel.textColor = self.pressedTextColor;
        self.backgroundColor = self.pressedBackgroundColor;
        self.textLabel.text = self.pressedText;
    }
    [self invalidateIntrinsicContentSize];
    [self setNeedsUpdateConstraints];
}

- (void)setNormalText:(NSString *)normalText
{
    _normalText = normalText;
    [self setState:self.state];
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

- (CGFloat)distanceBetweenPoint1:(CGPoint)point1 point2:(CGPoint)point2
{
    return sqrt(pow(point2.x-point1.x,2)+pow(point2.y-point1.y,2));
}

- (BOOL)touch:(UITouch *)touch leftRadius:(double)radius
{
    CGPoint touchLocation = [touch locationInView:self];
    
    
    //Match touch Location to point on frame. If inside then the pointOnFrame == touchLocation and caclulatedRadius == 0
    CGPoint pointOnFrame = touchLocation;
    CGFloat height = CGRectGetHeight(self.frame);
    CGFloat width = CGRectGetWidth(self.frame);
    if (touchLocation.x < 0) {
        pointOnFrame.x = 0;
    } else if (touchLocation.x > width) {
        pointOnFrame.x = width;
    }
    
    if (touchLocation.y < 0) {
        pointOnFrame.y = 0;
    } else if (touchLocation.y > height) {
        pointOnFrame.y = height;
    }
    
    CGFloat cacluatedRadius = [self distanceBetweenPoint1:touchLocation point2:pointOnFrame];
    NSLog(@"Distance %f",cacluatedRadius);
    return cacluatedRadius > radius;
}

#pragma - mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = OTRHoldToTalkViewStatePressed;
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
    self.state = OTRHoldToTalkViewStateNormal;
    [self.delegate didReleaseTouch:self];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = OTRHoldToTalkViewStateNormal;
    [self.delegate touchCancelled:self];
}


@end
