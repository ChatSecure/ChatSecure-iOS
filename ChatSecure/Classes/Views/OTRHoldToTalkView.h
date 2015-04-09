//
//  OTRHoldToTalkView.h
//  ChatSecure
//
//  Created by David Chiles on 4/1/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRHoldToTalkView;

typedef NS_ENUM(NSUInteger, OTRHoldToTalkViewState) {
    OTRHoldToTalkViewStateNormal = 0,
    OTRHoldToTalkViewStatePressed = 1
};

@protocol OTRHoldToTalkViewStateDelegate <NSObject>

@required
- (void)didBeginTouch:(OTRHoldToTalkView *)view;
- (void)didReleaseTouch:(OTRHoldToTalkView *)view;
- (void)view:(OTRHoldToTalkView *)view touchDidMoveToPointInWindow:(CGPoint)point;
- (void)touchCancelled:(OTRHoldToTalkView *)view;

@end

@interface OTRHoldToTalkView : UIView

@property (nonatomic) OTRHoldToTalkViewState state;

@property (nonatomic, strong) NSString *normalText;
@property (nonatomic, strong) UIColor *normalTextColor;

@property (nonatomic, strong) NSString *pressedText;
@property (nonatomic, strong) UIColor *pressedTextColor;

@property (nonatomic, strong) UIColor *normalBackgroundColor;
@property (nonatomic, strong) UIColor *pressedBackgroundColor;

@property (nonatomic, weak) id <OTRHoldToTalkViewStateDelegate> delegate;

@end
