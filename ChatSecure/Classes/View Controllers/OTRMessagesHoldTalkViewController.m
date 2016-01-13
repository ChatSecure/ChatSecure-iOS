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
#import "OTRStrings.h"
@import OTRKit;
#import "OTRBuddy.h"
#import "OTRXMPPManager.h"
#import "OTRXMPPAccount.h"
#import "OTRLanguageManager.h"

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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateEncryptionState];
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
    
    CGFloat offset = 1;
    
    [self.hold2TalkButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:textView withOffset:-offset];
    [self.hold2TalkButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:textView withOffset:offset];
    [self.hold2TalkButton autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:textView withOffset:-offset];
    [self.hold2TalkButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:textView withOffset:offset];
    
    
    [self.view setNeedsUpdateConstraints];
}

- (void)setHold2TalkStatusWaiting
{
    self.hold2TalkButton.textLabel.text = HOLD_TO_TALK_STRING;
    self.hold2TalkButton.textLabel.textColor = [UIColor whiteColor];
    self.hold2TalkButton.backgroundColor = [UIColor darkGrayColor];
}

- (void)setHold2TalkButtonRecording
{
    self.hold2TalkButton.textLabel.text = RELEASE_TO_SEND_STRING;
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
    self.trashView.trashLabel.textColor = [UIColor whiteColor];
}

- (void)addRecordingBackgroundView
{
    self.recordingBackgroundView = [[UIView alloc] initForAutoLayout];
    self.recordingBackgroundView.backgroundColor = [UIColor grayColor];
    self.recordingBackgroundView.alpha = 0.7;
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

#pragma - mark JSQMessageViewController

- (void)receivedTextViewChangedNotification:(NSNotification *)notification
{
    [self textViewDidChange:notification.object];
}

- (void)textViewDidChange:(UITextView *)textView
{
    OTRXMPPManager *xmppManager = [self xmppManager];
    OTRBuddy *buddy = (OTRBuddy *)[self threadObject];
    if ([textView.text length]) {
        self.inputToolbar.contentView.rightBarButtonItem = self.sendButton;
        self.inputToolbar.sendButtonLocation = JSQMessagesInputSendButtonLocationRight;
        self.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
        //typing
        [xmppManager sendChatState:kOTRChatStateComposing withBuddyID:buddy.uniqueId];
    }
    else {
        [[OTRKit sharedInstance] messageStateForUsername:buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(OTRKitMessageState messageState) {
            if (messageState == OTRKitMessageStateEncrypted) {
                
                if ([self.hold2TalkButton superview]) {
                     self.inputToolbar.contentView.rightBarButtonItem = self.keyboardButton;
                } else {
                     self.inputToolbar.contentView.rightBarButtonItem = self.microphoneButton;
                }
               
                self.inputToolbar.sendButtonLocation = JSQMessagesInputSendButtonLocationNone;
                self.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
            }
        }];
        
        //done typing
        [xmppManager sendChatState:kOTRChatStateActive withBuddyID:buddy.uniqueId];
        
    }
}

- (void)setupAccessoryButtonsWithMessageState:(OTRKitMessageState)messageState
{
    //set correct camera and microphone
    if (messageState == OTRKitMessageStateEncrypted) {
        if (![self.inputToolbar.contentView.textView.text length]) {
            
            if ([self.hold2TalkButton superview]) {
                self.inputToolbar.contentView.rightBarButtonItem = self.keyboardButton;
            } else {
                self.inputToolbar.contentView.rightBarButtonItem = self.microphoneButton;
            }
            
            self.inputToolbar.sendButtonLocation = JSQMessagesInputSendButtonLocationNone;
            self.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
        }
        self.inputToolbar.contentView.leftBarButtonItem = self.cameraButton;
    }
    else {
        [self removePush2TalkButton];
        [self removeRecordingBackgroundView];
        [self removeTrashViewItems];
        self.inputToolbar.contentView.rightBarButtonItem = self.sendButton;
        self.inputToolbar.sendButtonLocation = JSQMessagesInputSendButtonLocationRight;
        self.inputToolbar.contentView.leftBarButtonItem = nil;
    }
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
        self.hold2TalkButton.textLabel.text = RELEASE_TO_DELETE_STRING;
    } else {
        self.trashView.trashIconLabel.alpha = percentDistance;
        self.trashView.microphoneIconLabel.alpha = 1-percentDistance;
        self.hold2TalkButton.textLabel.text = RELEASE_TO_SEND_STRING;
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
    double scale = 0;
    //Values for human speech range quiet to loud
    double mindB = -80;
    double maxdB = -10;
    if (decibel >= maxdB) {
        //too loud
        scale = 1;
    } else if (decibel >= mindB && decibel <= maxdB) {
        //normal voice
        double powerFactor = 20;
        double mindBScale = pow(10, mindB / powerFactor);
        double maxdBScale = pow(10, maxdB / powerFactor);
        double linearScale = pow (10, decibel / powerFactor);
        double scaleMin = 0;
        double scaleMax = 1;
        //Get a value between 0 and 1 for mindB & maxdB values
        scale = ( ((scaleMax - scaleMin) * (linearScale - mindBScale)) / (maxdBScale - mindBScale)) + scaleMin;
    }
    
    [self.trashView setAnimationChange:30 * scale];
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
