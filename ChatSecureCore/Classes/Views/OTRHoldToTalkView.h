//
//  OTRHoldToTalkView.h
//  ChatSecure
//
//  Created by David Chiles on 4/1/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import UIKit;

@class OTRHoldToTalkView;

@protocol OTRHoldToTalkViewStateDelegate <NSObject>

@required
- (void)didBeginTouch:(OTRHoldToTalkView *)view;
- (void)didReleaseTouch:(OTRHoldToTalkView *)view;
- (void)view:(OTRHoldToTalkView *)view touchDidMoveToPointInWindow:(CGPoint)point;
- (void)touchCancelled:(OTRHoldToTalkView *)view;

@end

@interface OTRHoldToTalkView : UIView

@property (nonatomic, strong, readonly) UILabel *textLabel;

@property (nonatomic, weak) id <OTRHoldToTalkViewStateDelegate> delegate;
- (BOOL) isInTouch;

@end
