//
//  OTRMessagesHoldTalkViewController.m
//  ChatSecure
//
//  Created by David Chiles on 4/1/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesHoldTalkViewController.h"
#import "PureLayout.h"
#import "OTRHoldToTalkView.h"
#import "OTRAudioSessionManager.h"
#import "OTRAudioTrashView.h"


@interface OTRMessagesHoldTalkViewController () <OTRHoldToTalkViewStateDelegate>

@property (nonatomic, strong) OTRHoldToTalkView *hold2TalkButton;
@property (nonatomic, strong) OTRAudioTrashView *trashView;

@property (nonatomic, strong) NSLayoutConstraint *trashViewWidthConstraint;

@property (nonatomic, strong) UIButton *keyboardButton;

@property (nonatomic) BOOL holdTalkAddedConstraints;

@property (nonatomic, strong) OTRAudioSessionManager *audioSessionManager;

@end

@implementation OTRMessagesHoldTalkViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioSessionManager = [[OTRAudioSessionManager alloc] init];
    
    self.hold2TalkButton = [[OTRHoldToTalkView alloc] initForAutoLayout];
    self.hold2TalkButton.normalText = @"Hold to talk";
    self.hold2TalkButton.pressedText = @"Release to send";
    self.hold2TalkButton.delegate = self;
    
    self.trashView = [[OTRAudioTrashView alloc] initForAutoLayout];
    
    self.keyboardButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.keyboardButton.frame = CGRectMake(0, 0, 22, 32);
    self.keyboardButton.titleLabel.font = [UIFont fontWithName:kFontAwesomeFont size:20];
    self.keyboardButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.keyboardButton setTitle:[NSString fa_stringForFontAwesomeIcon:FAKeyboardO]
                           forState:UIControlStateNormal];
    
    [self.view setNeedsUpdateConstraints];
}

#pragma - mark AutoLayout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.trashView.trashButton.buttonCornerRadius = @(CGRectGetWidth(self.trashView.trashButton.bounds));
}

#pragma - mark Utilities

- (CGFloat)distanceBetweenPoint1:(CGPoint)point1 point2:(CGPoint)point2
{
    return sqrt(pow(point2.x-point1.x,2)+pow(point2.y-point1.y,2));
}

- (CGPoint)centerOfview:(UIView *)view1 inView:(UIView *)view2
{
    CGPoint localCenter = CGPointMake(CGRectGetMidX(view1.bounds), CGRectGetMidY(view1.bounds));
    CGPoint trashButtonCenter = [view2 convertPoint:localCenter fromView:view1];
    return trashButtonCenter;
}

#pragma - mark Setup Recording

- (void)addPush2TalkButton
{
    [self.view addSubview:self.hold2TalkButton];
    
    UIView *textView = self.inputToolbar.contentView.textView;
    
    [self.hold2TalkButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:textView];
    [self.hold2TalkButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:textView];
    [self.hold2TalkButton autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:textView];
    [self.hold2TalkButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:textView];
    
    
    [self.view setNeedsUpdateConstraints];
}

- (void)addTrashViewItems
{
    [self.view addSubview:self.trashView];
    
    [self.trashView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.view withOffset:50];
    [self.trashView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    self.trashViewWidthConstraint = [self.trashView autoSetDimension:ALDimensionHeight toSize:self.trashView.intrinsicContentSize.height];
}

- (void)removePush2TalkButton
{
    [self.hold2TalkButton removeFromSuperview];
}

- (void)removeTrashViewItems
{
    [self.trashView removeFromSuperview];
    
}

#pragma - mark OTRHoldToTalkViewStateDelegate

- (void)didBeginTouch:(OTRHoldToTalkView *)view
{
    //start Recording
    [self addTrashViewItems];
    NSString *temporaryPath = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"%@.m4a",[[NSUUID UUID] UUIDString]];
    NSURL *url = [NSURL fileURLWithPath:[temporaryPath stringByAppendingPathComponent:fileName]];
    [self.audioSessionManager recordAudioToURL:url error:nil];
}

- (void)view:(OTRHoldToTalkView *)view touchDidMoveToPointInWindow:(CGPoint)point
{
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    CGPoint poinInView = [self.view convertPoint:point fromView:mainWindow];
    
    CGPoint trashButtonCenter = [self centerOfview:self.trashView.trashButton inView:self.view];
    CGPoint holdToTalkCenter = [self centerOfview:self.hold2TalkButton inView:self.view];
    
    CGFloat normalDistance = [self distanceBetweenPoint1:trashButtonCenter point2:holdToTalkCenter];
    
    CGFloat distance = [self distanceBetweenPoint1:poinInView point2:trashButtonCenter];
    
    CGFloat defaultHeight = self.trashView.intrinsicContentSize.height;
    self.trashViewWidthConstraint.constant = MAX(defaultHeight, defaultHeight+defaultHeight * (normalDistance - distance)/normalDistance);
    
    [self.view setNeedsUpdateConstraints];
    
    CGPoint testPoint = [self.trashView.trashButton convertPoint:poinInView fromView:self.view];
    BOOL insideButton = CGRectContainsPoint(self.trashView.trashButton.bounds, testPoint);
    
    self.trashView.trashButton.highlighted = insideButton;
    
}

- (void)didReleaseTouch:(OTRHoldToTalkView *)view
{
    //stop recording and send
    NSURL *currentURL = [self.audioSessionManager currentRecorderURL];
    [self.audioSessionManager stopRecording];
    //[self sendAudioFileURL:currentURL];
}

- (void)touchCancelled:(OTRHoldToTalkView *)view
{
    //sto recording and delete
    NSURL *currentURL = [self.audioSessionManager currentRecorderURL];
    [self.audioSessionManager stopRecording];
    [self.audioSessionManager stopRecording];
    if([[NSFileManager defaultManager] fileExistsAtPath:currentURL.path]) {
        [[NSFileManager defaultManager] removeItemAtPath:currentURL.path error:nil];
    }
}


#pragma - mark JSQMessagesDelegate

- (void)didPressAccessoryButton:(UIButton *)sender
{
    if ([sender isEqual:self.microphoneButton]) {
        [self.view endEditing:YES];
        [self addPush2TalkButton];
        
        self.inputToolbar.contentView.rightBarButtonItem = self.keyboardButton;
    } else if ([sender isEqual:self.keyboardButton]) {
        [self removePush2TalkButton];
        [self removeTrashViewItems];
        [self.inputToolbar.contentView.textView becomeFirstResponder];
        self.inputToolbar.contentView.rightBarButtonItem = self.microphoneButton;
    } else {
        [super didPressAccessoryButton:sender];
    }
}

@end
