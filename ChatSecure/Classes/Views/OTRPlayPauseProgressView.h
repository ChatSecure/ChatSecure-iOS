//
//  OTRPlayPauseProgressView.h
//  ChatSecure
//
//  Created by David Chiles on 1/29/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, OTRPlayPauseProgressViewStatus) {
    OTRPlayPauseProgressViewStatusPlay,
    OTRPlayPauseProgressViewStatusPause
};

@interface OTRPlayPauseProgressView : UIView

@property (nonatomic) OTRPlayPauseProgressViewStatus status;
@property (nonatomic, strong) UIColor *color;

- (void)animateProgressArcWithFromValue:(CGFloat)fromValue duration:(NSTimeInterval)duration;

- (void)setProgressArcValue:(CGFloat)value;

- (void)removeProgressArc;

@end
