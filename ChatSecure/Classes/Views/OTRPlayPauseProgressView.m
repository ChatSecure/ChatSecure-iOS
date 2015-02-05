//
//  OTRPlayPauseProgressView.m
//  ChatSecure
//
//  Created by David Chiles on 1/29/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRPlayPauseProgressView.h"
#import "OTRPlayView.h"
#import "OTRPauseView.h"
#import "PureLayout.h"

NSString *const kOTRPlayProgressAnimationKey = @"kOTRPlayProgressAnimationKey";

@interface OTRPlayPauseProgressView ()

@property (nonatomic, strong) OTRPlayView *playView;
@property (nonatomic, strong) OTRPauseView *pauseView;
@property (nonatomic) BOOL addedConstraints;

@property (nonatomic, strong) NSArray *playViewConstraints;
@property (nonatomic, strong) NSArray *pauseViewConstraints;

@property (nonatomic, strong) CAShapeLayer *percentShapeLayer;

@end

@implementation OTRPlayPauseProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.addedConstraints = NO;
        self.playView = [[OTRPlayView alloc] initForAutoLayout];
        self.pauseView = [[OTRPauseView alloc] initForAutoLayout];
        self.status = OTRPlayPauseProgressViewStatusPlay;
        self.percent = 0;
        self.color = [UIColor blackColor];
        
        self.percentShapeLayer = [[CAShapeLayer alloc] init];
        self.percentShapeLayer.strokeColor = self.color.CGColor;
        self.percentShapeLayer.strokeEnd = 0;
        self.percentShapeLayer.strokeStart = 0;
        self.percentShapeLayer.lineWidth = 2.5;
        self.percentShapeLayer.fillColor = nil;
        
        [self addSubview:self.playView];
        [self.layer addSublayer:self.percentShapeLayer];
    }
    return self;
}

- (UIBezierPath *)progressPathInRect:(CGRect)rect lineWidth:(CGFloat)lineWidth
{
    
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGFloat startAngle = 3 * M_PI / 2;
    CGFloat endAngle = M_PI * 2 + startAngle;
    CGFloat radius = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect))/2;
    
    UIBezierPath *progressPath = [UIBezierPath bezierPathWithArcCenter:center
                                                                radius:radius
                                                            startAngle:startAngle
                                                              endAngle:endAngle
                                                             clockwise:YES];
    
    // Set the display for the path, and stroke it
    progressPath.lineWidth = lineWidth;
    
    return progressPath;
}

- (void)drawCircleInRect:(CGRect)rect
{
    CGFloat lineWidth = 1;
    CGFloat diameter = MIN(CGRectGetHeight(rect), CGRectGetWidth(rect));
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(lineWidth/2, lineWidth/2, diameter-lineWidth, diameter-lineWidth)];
    [self.color setStroke];
    ovalPath.lineWidth = lineWidth;
    [ovalPath stroke];
}

- (void)setColor:(UIColor *)color
{
    if (![_color isEqual:color]) {
        _color = color;
        self.percentShapeLayer.strokeColor = color.CGColor;
        self.playView.color = color;
        self.pauseView.color = color;
    }
}

- (void)setPercent:(CGFloat)percent
{
    if (percent > 1) {
        _percent = 1;
    }
    else if (percent < 0){
        _percent = 0;
    }
    else {
        _percent = percent;
    }
}

- (void)setPercent:(CGFloat)percent duration:(NSTimeInterval)duration
{
    CGFloat oldPercent  = self.percent;
    self.percent = percent;
    if (duration > 0) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:NSStringFromSelector(@selector(strokeEnd))];
        animation.fromValue = nil;
        if (oldPercent == 0) {
            animation.fromValue = @(oldPercent);
        }
        animation.toValue = @(self.percent);
        animation.duration = duration;
        self.percentShapeLayer.strokeEnd = percent;
        [self.percentShapeLayer addAnimation:animation forKey:kOTRPlayProgressAnimationKey];
    }
    else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.percentShapeLayer.strokeEnd = self.percent;
        [CATransaction commit];
    }
}

- (void)setStatus:(OTRPlayPauseProgressViewStatus)status
{
    _status = status;
    
    switch (self.status) {
        case OTRPlayPauseProgressViewStatusPlay:
            [self removePauseView];
            [self addPlayView];
            break;
        case OTRPlayPauseProgressViewStatusPause:
            [self removePlayView];
            [self addPauseView];
            break;
        default:
            break;
    }
}

- (void)removePlayView
{
    [self.playView removeFromSuperview];
    [self removeConstraints:self.playViewConstraints];
    self.playViewConstraints = nil;
}

- (void)removePauseView
{
    [self.pauseView removeFromSuperview];
    [self removeConstraints:self.pauseViewConstraints];
    self.pauseViewConstraints = nil;
}

- (void)addPlayView
{
    if (!self.playView.superview) {
        [self addSubview:self.playView];
        [self setNeedsUpdateConstraints];
    }
    
}

- (void)addPauseView
{
    if (!self.pauseView.superview) {
        [self addSubview:self.pauseView];
        [self setNeedsUpdateConstraints];
    }

}

- (void)updateConstraints
{
    [super updateConstraints];
    if (self.playView.superview) {
        CGFloat playInset = 7;
        self.playViewConstraints = [self.playView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(playInset, playInset, playInset, playInset)];
    }
    else if (self.pauseView.superview) {
        CGFloat pauseInset = 9;
        self.pauseViewConstraints = [self.pauseView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(pauseInset, pauseInset, pauseInset, pauseInset)];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updatePercentPathInRect:self.bounds];
}

- (void)drawRect:(CGRect)rect
{
    [self drawCircleInRect:rect];
}

- (void)updatePercentPathInRect:(CGRect)rect
{
    CGFloat progressInset = 1.5;
    CGRect progressRect = CGRectInset(rect, progressInset, progressInset);
    self.percentShapeLayer.path = [self progressPathInRect:progressRect lineWidth:progressInset + 1].CGPath;
}

@end
