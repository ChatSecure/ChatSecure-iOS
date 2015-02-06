//
//  OTRPlayPauseProgressView.h
//  ChatSecure
//
//  Created by David Chiles on 1/29/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, OTRPlayPauseProgressViewStatus) {
    OTRPlayPauseProgressViewStatusPlay,
    OTRPlayPauseProgressViewStatusPause
};

@interface OTRPlayPauseProgressView : UIView

@property (nonatomic) OTRPlayPauseProgressViewStatus status;
@property (nonatomic, strong) UIColor *color;

- (void)startProgressCircleWithDuration:(NSTimeInterval)duration;

- (void)removeProgressCircle;

- (void)pauseAnimation;

- (void)resumeAnimation;

@end
