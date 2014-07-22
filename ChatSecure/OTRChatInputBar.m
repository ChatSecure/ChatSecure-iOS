//
//  OTRChatInputBar.m
//  Off the Record
//
//  Created by David on 9/20/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

/**
 *Delegate call back for when size changes
 *Delegate call back for when typing and text for sending typing notifications
 
 */

#import "OTRChatInputBar.h"
#import "Strings.h"
#import "OTRConstants.h"
#import "OTRColors.h"
#import "OTRUtilities.h"


@implementation OTRChatInputBar

- (id)initWithFrame:(CGRect)frame withDelegate:(id<OTRChatInputBarDelegate>)newDelegate;
{
    if (self = [self initWithFrame:frame])
    {
        self.delegate = newDelegate;
        self.opaque = YES;
        self.userInteractionEnabled = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        [self addSubview:self.backgroundImageview];
        
        [self addSubview:self.sendButton];
        [self addSubview:self.textView];
        if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            [self addSubview:self.textViewBackgroundImageView];
        }
        
        
        
        [self checkSaveButton];
        
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (UIButton *)classicButton
{
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat buttonWidth = [SEND_STRING sizeWithAttributes:
                           @{NSFontAttributeName:[UIFont systemFontOfSize:16]}].width+20;
    button.frame = CGRectMake(self.frame.size.width - (buttonWidth+6), 8, buttonWidth, 27);
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    UIEdgeInsets sendButtonEdgeInsets = UIEdgeInsetsMake(0, 13, 0, 13); // 27 x 27
    UIImage *sendButtonBackgroundImage = [[UIImage imageNamed:@"SendButton"] resizableImageWithCapInsets:sendButtonEdgeInsets];
    [button setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateNormal];
    [button setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateDisabled];
    [button setBackgroundImage:[[UIImage imageNamed:@"SendButtonHighlighted"] resizableImageWithCapInsets:sendButtonEdgeInsets] forState:UIControlStateHighlighted];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    button.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [button setTitleShadowColor:[UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1] forState:UIControlStateNormal];
    
    return button;
}

- (UIButton *)flatButton
{
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat buttonWidth = [SEND_STRING sizeWithAttributes:
                           @{NSFontAttributeName:[UIFont systemFontOfSize:16]}].width+20;
    button.frame = CGRectMake(self.frame.size.width - (buttonWidth+6), 8, buttonWidth, 27);
    button.backgroundColor = [UIColor clearColor];
    
    [button setTitleColor:[OTRColors bubbleBlueColor] forState:UIControlStateNormal];
    [button setTitleColor:[OTRColors bubbleBlueColor] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1] forState:UIControlStateDisabled];
    
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    return button;
}

- (UIButton *)sendButton
{
    if (!_sendButton) {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _sendButton = [self flatButton];
        }
        else{
            _sendButton = [self classicButton];
        }
        
        NSString *title = SEND_STRING;
        [_sendButton setTitle:title forState:UIControlStateNormal];
        [_sendButton setTitle:title forState:UIControlStateHighlighted];
        [_sendButton setTitle:title forState:UIControlStateDisabled];
        
        _sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin);
        
        [_sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        
        previousTextViewContentHeight = kOTRMessageFontSize+20;
    }
    return _sendButton;
}

-(HPGrowingTextView *)textView
{
    if(!_textView) {
        CGFloat rightEdge = self.sendButton.frame.origin.x - 8;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(6, 4, rightEdge-6, 34)];
            _textView.backgroundColor = [UIColor clearColor];
            _textView.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
            _textView.layer.borderWidth = 0.65f;
            _textView.layer.cornerRadius = 6.0f;
        }
        else {
            _textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(6, 4, rightEdge-6, 34)];
            _textView.backgroundColor = [UIColor whiteColor];
        }
        
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        _textView.isScrollable = NO;
        _textView.delegate = self;
        _textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        _textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        
        _textView.minNumberOfLines = 1;
        _textView.maxNumberOfLines = 2;
        _textView.animateHeightChange = YES;
        _textView.animationDuration = 0.1;
        
        _textView.font = [UIFont systemFontOfSize:kOTRMessageFontSize];
        _textView.placeholder = MESSAGE_PLACEHOLDER_STRING;
        
        _textView.clipsToBounds = YES;
        
        
    }
    return _textView;
}

-(void)growingTextViewDidChange:(HPGrowingTextView *)textView
{
    [self checkSaveButton];
}

-(void)checkSaveButton
{
    if ([self.textView.text length]) {
        self.sendButton.enabled = YES;
        self.sendButton.titleLabel.alpha = 1;
    } else {
        self.sendButton.enabled = NO;
        if(SYSTEM_VERSION_LESS_THAN(@"7.0"))
        {
            self.sendButton.titleLabel.alpha = 0.5f;
        }
    }
}

- (UIImageView *)backgroundImageview
{
    if (!_backgroundImageview) {
        _backgroundImageview = [[UIImageView alloc] init];
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _backgroundImageview.image = [[UIImage imageNamed:@"input-bar-flat"] resizableImageWithCapInsets:UIEdgeInsetsMake(19, 3, 19, 3)];
        }
        else {
            _backgroundImageview.image = [[UIImage imageNamed:@"MessageInputBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(2.0, 0.0, 0.0, 0.0)];
        }
        
        
        _backgroundImageview.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _backgroundImageview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return _backgroundImageview;
}

-(UIImageView *)textViewBackgroundImageView
{
    if(!_textViewBackgroundImageView)
    {
        UIImage * backgroundImage;
        backgroundImage = [UIImage imageNamed:@"MessageInputFieldBackground"];
        backgroundImage = [backgroundImage stretchableImageWithLeftCapWidth:13 topCapHeight:22];
        _textViewBackgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
        CGRect frame = self.textView.frame;
        frame.origin.x = 5;
        frame.origin.y = 0;
        frame.size.height = 40;
        frame.size.width = frame.size.width +8;
        _textViewBackgroundImageView.frame = frame;
        _textViewBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return _textViewBackgroundImageView;
}

- (void)sendButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(sendButtonPressedForInputBar:)]) {
        [self.delegate sendButtonPressedForInputBar:self];
    }
}

#pragma mark UITextViewDelegate
- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
	CGRect rect = self.frame;
    rect.size.height -= diff;
    rect.origin.y += diff;
    self.frame = rect;
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    if ([self.delegate respondsToSelector:@selector(didChangeFrameForInputBur:)]) {
        [self.delegate didChangeFrameForInputBur:self];
    }
	
}

-(BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([self.delegate respondsToSelector:@selector(inputBar:shouldChangeTextInRange:replacementText:)]) {
        return [self.delegate inputBar:self shouldChangeTextInRange:range replacementText:text];
    }
    return YES;
}

-(void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView
{
    if ([self.delegate respondsToSelector:@selector(inputBarDidBeginEditing:)]) {
        [self.delegate inputBarDidBeginEditing:self];
    }
}

@end
