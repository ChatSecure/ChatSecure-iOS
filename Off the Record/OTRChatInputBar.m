//
//  OTRChatInputBar.m
//  Off the Record
//
//  Created by David on 9/20/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRChatInputBar.h"
#import "Strings.h"
#import "OTRConstants.h"


@implementation OTRChatInputBar

@synthesize textView = _textView;
@synthesize backgroundImageview = _backgroundImageview;
@synthesize textViewBackgroundImageView = _textViewBackgroundImageView;
@synthesize sendButton =_sendButton;
@synthesize buttonBlock;

- (id)initWithFrame:(CGRect)frame withSendButtonPressedBlock:(sendButtonBlock)block
{
    if (self = [self initWithFrame:frame])
    {
        self.buttonBlock = block;
        self.opaque = YES;
        self.userInteractionEnabled = YES;
        
        [self addSubview:self.backgroundImageview];
        [self addSubview:self.textViewBackgroundImageView];
        [self addSubview:self.sendButton];
        [self addSubview:self.textView];
        //self.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (UIButton *)sendButton
{
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.translatesAutoresizingMaskIntoConstraints = NO;
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

-(UITextView *)textView
{
    if(!_textView) {
        _textView = [[ACPlaceholderTextView alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor clearColor]; //[UIColor colorWithWhite:245/255.0f alpha:1];
        _textView.scrollIndicatorInsets = UIEdgeInsetsMake(13, 0, 8, 6);
        _textView.contentInset = UIEdgeInsetsMake(4, 4, 0, 0);
        _textView.scrollsToTop = NO;
        _textView.font = [UIFont systemFontOfSize:MessageFontSize];
        _textView.placeholder = MESSAGE_PLACEHOLDER_STRING;
        
        _textView.clipsToBounds = YES;
    }
    return _textView;
}

- (UIImageView *)backgroundImageview
{
    if (!_backgroundImageview) {
        _backgroundImageview = [[UIImageView alloc] init];
        _backgroundImageview.translatesAutoresizingMaskIntoConstraints = NO;
        _backgroundImageview.image = [[UIImage imageNamed:@"MessageInputBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(19, 3, 19, 3)];
    }
    return _backgroundImageview;
}

-(UIImageView *)textViewBackgroundImageView
{
    if(!_textViewBackgroundImageView)
    {
        _textViewBackgroundImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"MessageInputFieldBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 12, 18, 18)]];
        _textViewBackgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _textViewBackgroundImageView.backgroundColor = [UIColor colorWithWhite:245/255.0f alpha:1];
        
    }
    return _textViewBackgroundImageView;
}

- (void)sendButtonPressed:(id)sender
{
    if (self.buttonBlock) {
        self.buttonBlock(self.textView.text);
    }
}

#pragma mark UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat textViewContentHeight = textView.contentSize.height;
    CGFloat changeInHeight = textViewContentHeight - previousTextViewContentHeight;
    
    if (textViewContentHeight+changeInHeight > kChatBarHeight4+2) {
        changeInHeight = kChatBarHeight4+2-previousTextViewContentHeight;
    }
    
    float duration = 0.2f;
    
    
    if (changeInHeight) {
        [textViewHeightConstraint setConstant:MIN(textViewContentHeight, ContentHeightMax)];
        /*
        [UIView animateWithDuration:duration animations:^{
            
            
            //self.chatHistoryTableView.contentInset = self.chatHistoryTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.chatHistoryTableView.contentInset.bottom+changeInHeight, 0);
            //[self scrollToBottomAnimated:NO];
            
            
            //self.view.keyboardTriggerOffset = messageInputBar.frame.size.height;
        } completion:^(BOOL finished) {
            
        }];
         */
        self.frame = CGRectMake(0, self.frame.origin.y-changeInHeight, self.frame.size.width, self.frame.size.height+changeInHeight);
        [self needsUpdateConstraints];
        [self.textView updateShouldDrawPlaceholder];
        previousTextViewContentHeight = MIN(textViewContentHeight, kChatBarHeight4+2);
        
    }
}



-(void)updateConstraints
{
    [super updateConstraints];
    
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
                                                 toItem:self
                                              attribute:NSLayoutAttributeLeft
                                             multiplier:1.0
                                               constant:TEXT_VIEW_X];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.textView
                                              attribute:NSLayoutAttributeRight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.sendButton
                                              attribute:NSLayoutAttributeLeft
                                             multiplier:1.0
                                               constant:-4.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.textView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:-4.0];
    [self addConstraint:constraint];
    textViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.textView
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:1.0
                                               constant:TEXT_VIEW_HEIGHT_MIN];
    [self addConstraint:textViewHeightConstraint];
    
    //TEXT VIEW BACKGROUND IMAGE VIEW
    constraint = [NSLayoutConstraint constraintWithItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeLeft
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.textView
                                              attribute:NSLayoutAttributeLeft
                                             multiplier:1.0
                                               constant:-2.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.textView
                                              attribute:NSLayoutAttributeTop
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.textView
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:1.0
                                               constant:9.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.textViewBackgroundImageView
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.textView
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    
    
    
}

@end
