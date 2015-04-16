//
//  OTRCircleView.m
//  ChatSecure
//
//  Created by David Chiles on 4/9/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRCircleView.h"

@implementation OTRCircleView

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    
    CGFloat diameter = MIN(width, height);
    
    CGFloat x = (width - diameter) / 2;
    CGFloat y = (height - diameter) / 2;
    
    CAShapeLayer *circleShapeLayer = [[CAShapeLayer alloc] init];
    circleShapeLayer.path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(x, y, diameter, diameter)].CGPath;
    
    self.layer.mask = circleShapeLayer;
}

@end
