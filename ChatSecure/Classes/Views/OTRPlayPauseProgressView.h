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
@property (nonatomic) CGFloat percent;

- (void)setPercent:(CGFloat)percent duration:(NSTimeInterval)duration;

@end
