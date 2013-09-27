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


@implementation OTRChatInputBar

@synthesize textView = _textView;
@synthesize backgroundImageview = _backgroundImageview;
@synthesize textViewBackgroundImageView = _textViewBackgroundImageView;
@synthesize sendButton =_sendButton;
@synthesize delegate;

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
        [self addSubview:self.textViewBackgroundImageView];
        
        
        [self checkSaveButton];
        
        //self.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (UIButton *)sendButton
{
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.frame = CGRectMake(self.frame.size.width - 69, 8, 63, 27);
        _sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        UIEdgeInsets sendButtonEdgeInsets = UIEdgeInsetsMake(0, 13, 0, 13); // 27 x 27
        UIImage *sendButtonBackgroundImage = [[UIImage imageNamed:@"SendButton"] resizableImageWithCapInsets:sendButtonEdgeInsets];
        [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateNormal];
        [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateDisabled];
        [_sendButton setBackgroundImage:[[UIImage imageNamed:@"SendButtonHighlighted"] resizableImageWithCapInsets:sendButtonEdgeInsets] forState:UIControlStateHighlighted];
        _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _sendButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
        [_sendButton setTitle:SEND_STRING forState:UIControlStateNormal];
        [_sendButton setTitleShadowColor:[UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1] forState:UIControlStateNormal];
        [_sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        //CGFloat buttonWidth = [SEND_STRING sizeWithFont:[UIFont systemFontOfSize:16]].width+20;
        previousTextViewContentHeight = MessageFontSize+20;
    }
    return _sendButton;
}

-(HPGrowingTextView *)textView
{
    if(!_textView) {
        CGFloat rightEdge = self.sendButton.frame.origin.x - 8;
        _textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(6, 6, rightEdge-6, 34)];
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        //_textView = [[HPGrowingTextView alloc] initWithFrame:CGRectZero];
        _textView.isScrollable = NO;
        _textView.delegate = self;
        _textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        _textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        
        _textView.minNumberOfLines = 1;
        _textView.maxNumberOfLines = 2;
        _textView.animateHeightChange = YES;
        _textView.animationDuration = 0.1;
        //_textView.translatesAutoresizingMaskIntoConstraints = NO;
        //_textView.delegate = self;
        _textView.backgroundColor = [UIColor whiteColor];
        //_textView.contentInset = UIEdgeInsetsMake(-4, -4, -4, 0);
        //_textView.scrollsToTop = NO;
        _textView.font = [UIFont systemFontOfSize:MessageFontSize];
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
        self.sendButton.titleLabel.alpha = 0.5f;
    }
}

- (UIImageView *)backgroundImageview
{
    if (!_backgroundImageview) {
        _backgroundImageview = [[UIImageView alloc] init];
        _backgroundImageview.image = [[UIImage imageNamed:@"MessageInputBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(19, 3, 19, 3)];
        _backgroundImageview.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _backgroundImageview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return _backgroundImageview;
}

-(UIImageView *)textViewBackgroundImageView
{
    if(!_textViewBackgroundImageView)
    {
        UIImage *rawEntryBackground = [UIImage imageNamed:@"MessageInputFieldBackground"];
        UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
        _textViewBackgroundImageView = [[UIImageView alloc] initWithImage:entryBackground];
        CGRect frame = self.textView.frame;
        frame.origin.x = 5;
        frame.origin.y = 0;
        frame.size.height = 40;
        frame.size.width = frame.size.width +8;
        _textViewBackgroundImageView.frame = frame;
        _textViewBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        /*
        _textViewBackgroundImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"MessageInputFieldBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 12, 18, 18)]];
        _textViewBackgroundImageView.backgroundColor = [UIColor colorWithWhite:245/255.0f alpha:1];
        _textViewBackgroundImageView.frame = CGRectMake(5, 0, 248, 40);
        _textViewBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
         */
        
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

-(void)updateConstraints
{
    [super updateConstraints];
     /*
    //SEND BUTTON
    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.sendButton
                                                                   attribute:NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1.0
                                                                    constant:-7];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.sendButton
                                              attribute:NSLayoutAttributeRight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeRight
                                             multiplier:1.0
                                               constant:-6];
    [self addConstraint:constraint];
    
    CGFloat buttonWidth = [SEND_STRING sizeWithFont:[UIFont systemFontOfSize:16]].width+20;
    constraint = [NSLayoutConstraint constraintWithItem:self.sendButton
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:1.0
                                               constant:buttonWidth];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.sendButton
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:1.0
                                               constant:26.0];
    [self addConstraint:constraint];
    
    //BACKGROUND VIEW
    constraint = [NSLayoutConstraint constraintWithItem:self.backgroundImageview
                                              attribute:NSLayoutAttributeCenterX
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeCenterX
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.backgroundImageview
                                              attribute:NSLayoutAttributeCenterY
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeCenterY
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.backgroundImageview
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.backgroundImageview
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    //TEXT VIEW
   
    constraint = [NSLayoutConstraint constraintWithItem:self.textView
                                              attribute:NSLayoutAttributeLeft
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeLeft
                                             multiplier:1.0
                                               constant:6.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.textView
                                              attribute:NSLayoutAttributeRight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeRight
                                             multiplier:1.0
                                               constant:-6.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.textView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:-6.0];
    [self addConstraint:constraint];
    textViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.textView
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeTop
                                             multiplier:1.0
                                               constant:8.0];
    [self addConstraint:textViewHeightConstraint];
    
    
    
    //TEXT VIEW BACKGROUND IMAGE VIEW
    constraint = [NSLayoutConstraint constraintWithItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeLeft
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeLeft
                                             multiplier:1.0
                                               constant:5.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeTop
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeRight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.sendButton
                                              attribute:NSLayoutAttributeLeft
                                             multiplier:1.0
                                               constant:-4];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    */
    
    
}

@end
