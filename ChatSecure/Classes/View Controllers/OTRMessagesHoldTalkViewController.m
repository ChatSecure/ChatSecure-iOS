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


@interface OTRMessagesHoldTalkViewController () <OTRHoldToTalkViewStateDelegate, OTRAudioSessionManagerDelegate>

@property (nonatomic, strong) OTRHoldToTalkView *hold2TalkButton;
@property (nonatomic, strong) OTRAudioTrashView *trashView;

@property (nonatomic, strong) NSLayoutConstraint *trashViewWidthConstraint;

@property (nonatomic, strong) UIButton *keyboardButton;

@property (nonatomic) BOOL holdTalkAddedConstraints;

@property (nonatomic, strong) OTRAudioSessionManager *audioSessionManager;

@property (nonatomic, strong) UIView *recordingBackgroundView;

@end

@implementation OTRMessagesHoldTalkViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioSessionManager = [[OTRAudioSessionManager alloc] init];
    self.audioSessionManager.delegate = self;
    
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
    self.hold2TalkButton = [[OTRHoldToTalkView alloc] initForAutoLayout];
    [self setHold2TalkStatusWaiting];
    self.hold2TalkButton.delegate = self;
    [self.view addSubview:self.hold2TalkButton];
    
    UIView *textView = self.inputToolbar.contentView.textView;
    
    [self.hold2TalkButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:textView];
    [self.hold2TalkButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:textView];
    [self.hold2TalkButton autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:textView];
    [self.hold2TalkButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:textView];
    
    
    [self.view setNeedsUpdateConstraints];
}

- (void)setHold2TalkStatusWaiting
{
    self.hold2TalkButton.textLabel.text = @"Hold to talk";
    self.hold2TalkButton.textLabel.textColor = [UIColor whiteColor];
    self.hold2TalkButton.backgroundColor = [UIColor darkGrayColor];
}

- (void)setHold2TalkButtonRecording
{
    self.hold2TalkButton.textLabel.text = @"Release to send";
    self.hold2TalkButton.textLabel.textColor = [UIColor darkGrayColor];
    self.hold2TalkButton.backgroundColor = [UIColor whiteColor];
}

- (void)addTrashViewItems
{
    self.trashView = [[OTRAudioTrashView alloc] initForAutoLayout];
    [self.view addSubview:self.trashView];
    
    [self.trashView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.view withOffset:50];
    [self.trashView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    self.trashViewWidthConstraint = [self.trashView autoSetDimension:ALDimensionHeight toSize:self.trashView.intrinsicContentSize.height];
    self.trashView.trashIconLabel.alpha = 0;
    self.trashView.microphoneIconLabel.alpha = 1;
    self.trashView.trashButton.highlighted = NO;
}

- (void)addRecordingBackgroundView
{
    self.recordingBackgroundView = [[UIView alloc] initForAutoLayout];
    self.recordingBackgroundView.backgroundColor = [UIColor grayColor];
    self.recordingBackgroundView.alpha = 0.5;
    [self.view insertSubview:self.recordingBackgroundView belowSubview:self.hold2TalkButton];
    
    [self.recordingBackgroundView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

- (void)removeRecordingBackgroundView
{
    [self.recordingBackgroundView removeFromSuperview];
    self.recordingBackgroundView = nil;
}

- (void)removePush2TalkButton
{
    [self.hold2TalkButton removeFromSuperview];
    self.hold2TalkButton = nil;
}

- (void)removeTrashViewItems
{
    [self.trashView removeFromSuperview];
    self.trashView = nil;
    
}

#pragma - mark OTRHoldToTalkViewStateDelegate

- (void)didBeginTouch:(OTRHoldToTalkView *)view
{
    //start Recording
    [self addRecordingBackgroundView];
    [self addTrashViewItems];
    NSString *temporaryPath = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"%@.m4a",[[NSUUID UUID] UUIDString]];
    NSURL *url = [NSURL fileURLWithPath:[temporaryPath stringByAppendingPathComponent:fileName]];
    [self.audioSessionManager recordAudioToURL:url error:nil];
    [self setHold2TalkButtonRecording];
}

- (void)view:(OTRHoldToTalkView *)view touchDidMoveToPointInWindow:(CGPoint)point
{
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    CGPoint poinInView = [self.view convertPoint:point fromView:mainWindow];
    
    CGPoint trashButtonCenter = [self centerOfview:self.trashView.trashButton inView:self.view];
    CGPoint holdToTalkCenter = [self centerOfview:self.hold2TalkButton inView:self.view];
    
    CGFloat normalDistance = [self distanceBetweenPoint1:trashButtonCenter point2:holdToTalkCenter];
    
    CGFloat distance = [self distanceBetweenPoint1:poinInView point2:trashButtonCenter];
    
    CGFloat percentDistance = (normalDistance - distance)/normalDistance;
    CGFloat defaultHeight = self.trashView.intrinsicContentSize.height;
    self.trashViewWidthConstraint.constant = MAX(defaultHeight, defaultHeight+defaultHeight * percentDistance);
    
    CGPoint testPoint = [self.trashView.trashButton convertPoint:poinInView fromView:self.view];
    BOOL insideButton = CGRectContainsPoint(self.trashView.trashButton.bounds, testPoint);
    
    self.trashView.trashButton.highlighted = insideButton;
    
    if (insideButton) {
        self.trashView.trashIconLabel.alpha = 1;
        self.trashView.microphoneIconLabel.alpha = 0;
        self.hold2TalkButton.textLabel.text = @"Release to delete";
    } else {
        self.trashView.trashIconLabel.alpha = percentDistance;
        self.trashView.microphoneIconLabel.alpha = 1-percentDistance;
        self.hold2TalkButton.textLabel.text = @"Release to send";
    }
    
    [self.view setNeedsUpdateConstraints];
}

- (void)didReleaseTouch:(OTRHoldToTalkView *)view
{
    //stop recording and send
    NSURL *currentURL = [self.audioSessionManager currentRecorderURL];
    [self.audioSessionManager stopRecording];
    if (self.trashView.trashButton.isHighlighted) {
        if([[NSFileManager defaultManager] fileExistsAtPath:currentURL.path]) {
            [[NSFileManager defaultManager] removeItemAtPath:currentURL.path error:nil];
        }
    } else {
        [self sendAudioFileURL:currentURL];

    }
    
    [self removeTrashViewItems];
    [self setHold2TalkStatusWaiting];
    [self removeRecordingBackgroundView];
    
}

- (void)touchCancelled:(OTRHoldToTalkView *)view
{
    //stop recording and delete
    NSURL *currentURL = [self.audioSessionManager currentRecorderURL];
    [self.audioSessionManager stopRecording];
    if([[NSFileManager defaultManager] fileExistsAtPath:currentURL.path]) {
        [[NSFileManager defaultManager] removeItemAtPath:currentURL.path error:nil];
    }
    [self removeTrashViewItems];
    [self setHold2TalkStatusWaiting];
    [self removeRecordingBackgroundView];
}

#pragma - mark AudioSeessionDelegate

- (void)audioSession:(OTRAudioSessionManager *)audioSessionManager didUpdateRecordingDecibel:(double)decibel
{
    double linearScale = pow(10, decibel/20);
    [self.trashView setAnimationChange:100 * linearScale];
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
