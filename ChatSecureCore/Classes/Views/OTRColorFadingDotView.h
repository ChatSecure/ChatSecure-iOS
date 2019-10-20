//
//  OTRColorFadingDotImageView.h
//  Off the Record
//
//  Created by David Chiles on 1/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

@interface OTRColorFadingDotView : UIView

@property (nonatomic,strong) UIColor * animateToColor;
@property (nonatomic,readonly) CGFloat radius;
@property (nonatomic) NSTimeInterval animationDuration;

- (instancetype)initWithColor:(UIColor *)color radius:(CGFloat)radius;

- (void)startColorAnimationWithDelay:(NSTimeInterval)delay;
- (void)stopColorAnimation;


@end
