//
//  OTRChatInputBar.h
//  Off the Record
//
//  Created by David on 9/20/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"

@class OTRChatInputBar;

@protocol OTRChatInputBarDelegate <NSObject>

@optional
- (void)sendButtonPressedForInputBar:(OTRChatInputBar *)inputBar;
- (void)didChangeFrameForInputBur:(OTRChatInputBar *)inputBar;
- (BOOL)inputBar:(OTRChatInputBar *)inputBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)inputBarDidBeginEditing:(OTRChatInputBar *)inputBar;

@end

@interface OTRChatInputBar : UIView <HPGrowingTextViewDelegate>
{
    NSLayoutConstraint * textViewHeightConstraint;
    CGFloat previousTextViewContentHeight;
}


- (id)initWithFrame:(CGRect)frame withDelegate:(id<OTRChatInputBarDelegate>)delegate;

@property (nonatomic,strong) UIImageView * backgroundImageview;
@property (nonatomic,strong) UIImageView * textViewBackgroundImageView;
@property (nonatomic,strong) HPGrowingTextView * textView;
@property (nonatomic,strong) UIButton * sendButton;

@property (nonatomic,weak) id<OTRChatInputBarDelegate> delegate;

@end
