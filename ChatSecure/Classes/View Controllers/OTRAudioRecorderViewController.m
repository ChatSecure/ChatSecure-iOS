//
//  OTRAudioRecorderViewController.m
//  ChatSecure
//
//  Created by David Chiles on 2/11/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAudioRecorderViewController.h"
#import "OTRAudioSessionManager.h"
#import "OTRBuddy.h"
#import "OTRMessage.h"
#import "OTRAudioItem.h"
#import "PureLayout.h"
#import "Strings.h"
#import "OTRDatabaseManager.h"
#import "OTRUtilities.h"
#import "OTRImages.h"
#import "BButton.h"
#import "OTRColors.h"
#import "OTRMediaFileManager.h"

@import AVFoundation;

NSString *const kOTRAudioRecordAnimatePath = @"kOTRAudioRecordAnimatePath";

@interface OTRAudioRecorderViewController ()

@property (nonatomic, strong) OTRBuddy *buddy;
@property (nonatomic, strong) OTRAudioSessionManager *audioSessionManager;

@property (nonatomic) BOOL addedConstraints;

@property (nonatomic, strong) UIView *microphoneView;
@property (nonatomic, strong) UIView *blurredBackgroundView;
@property (nonatomic, strong) UIImageView *microphoneImageView;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UILabel *timerLabel;

@property (nonatomic, strong) NSLayoutConstraint *sendButtonBottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *cancelButtonBottomConstraint;

@property (nonatomic, strong) NSTimer *labelTimer;

@property (nonatomic) CGFloat microphoneRatio;

@end

@implementation OTRAudioRecorderViewController

- (instancetype) initWithBuddy:(OTRBuddy *)buddy
{
    if (self = [super init]) {
        self.buddy = buddy;
        self.audioSessionManager = [[OTRAudioSessionManager alloc] init];
        self.addedConstraints = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.bounds = CGRectZero;
    [maskLayer setFillColor:[[UIColor blackColor] CGColor]];
    self.blurredBackgroundView.layer.mask = maskLayer;
    self.blurredBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    self.microphoneView = [[UIView alloc] initWithFrame:CGRectZero];
    self.microphoneView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    UIColor *microphoneColor = [OTRColors defaultBlueColor];
    UIImage *microphoneImage = [OTRImages microphoneWithColor:microphoneColor size:CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
    self.microphoneRatio = microphoneImage.size.width / microphoneImage.size.height;
    self.microphoneImageView = [[UIImageView alloc] initWithImage:microphoneImage];
    self.microphoneView.contentMode = UIViewContentModeScaleAspectFit;
    self.microphoneImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(didPressSend:) forControlEvents:UIControlEventTouchUpInside];
    
    self.cancelButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeDefault style:BButtonStyleBootstrapV3 icon:FATimes fontSize:12.0];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton addTarget:self  action:@selector(didPressCancel:) forControlEvents:UIControlEventTouchUpInside];
    
    self.timerLabel = [[UILabel alloc] initForAutoLayout];
    self.timerLabel.textColor = [UIColor whiteColor];
    self.timerLabel.numberOfLines = 1;
    self.timerLabel.minimumScaleFactor = 0.5;
    self.timerLabel.adjustsFontSizeToFitWidth = YES;
    self.timerLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:self.blurredBackgroundView];
    [self.view addSubview:self.microphoneView];
    [self.microphoneView addSubview:self.microphoneImageView];
    [self.microphoneView addSubview:self.timerLabel];
    [self.view addSubview:self.sendButton];
    [self.view addSubview:self.cancelButton];
    
    [self.view setNeedsUpdateConstraints];
    
    self.view.backgroundColor = [UIColor clearColor];
}

#pragma - mark Presentation Methods

- (void)showAudioRecorderFromViewController:(UIViewController *)viewController animated:(BOOL)animated fromMicrophoneRectInWindow:(CGRect)rectInWindow
{
    //Pressenting ViewController on top of another http://www.raywenderlich.com/forums/viewtopic.php?f=2&t=18661
    self.providesPresentationContextTransitionStyle = YES;
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        self.modalPresentationCapturesStatusBarAppearance = UIModalPresentationOverCurrentContext;
    } else {
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
    }
    
    [viewController presentViewController:self animated:NO completion:^{
        //Animate microphon
        if (!animated) {
            return;
        }
        
        
        CGRect referenceFrameInMyView = [self.view convertRect:rectInWindow fromView:nil];
        self.microphoneView.frame = referenceFrameInMyView;
        
        
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.bounds = self.blurredBackgroundView.bounds;
        maskLayer.anchorPoint = CGPointMake(0, 0);
        CGFloat maxDimension = MAX(CGRectGetWidth(referenceFrameInMyView), CGRectGetHeight(referenceFrameInMyView));
        CGRect circleRect = referenceFrameInMyView;
        circleRect.size.height = maxDimension;
        circleRect.size.width = maxDimension;
        maskLayer.path = [UIBezierPath bezierPathWithOvalInRect:circleRect].CGPath;
        
        self.blurredBackgroundView.layer.mask = maskLayer;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSTimeInterval duration = 0.5;
                
                CGPathRef oldPath = maskLayer.path;
                CGFloat maxDimension = MAX(CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds));
                //Calculate square rect that is bounded by max dimension with same center point
                CGRect squareRect = CGRectInset(self.view.bounds, (CGRectGetWidth(self.view.bounds) - maxDimension)/2, (CGRectGetHeight(self.view.bounds)- maxDimension)/2);
                //Expand circle to twice the max dimension to cover entire view once done animating but still centered
                CGRect newCircleRect = CGRectInset(squareRect, -0.5 * maxDimension, -0.5 * maxDimension);
                CGPathRef newPath = [UIBezierPath bezierPathWithOvalInRect:newCircleRect].CGPath;
                
                CABasicAnimation* revealAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
                revealAnimation.fromValue = (__bridge id)(oldPath);
                revealAnimation.toValue = (__bridge id)(newPath);
                revealAnimation.duration = duration;
                
                [self.blurredBackgroundView.layer.mask addAnimation:revealAnimation forKey:kOTRAudioRecordAnimatePath];
                
                ((CAShapeLayer *)self.blurredBackgroundView.layer.mask).path = newPath;
                
                [UIView animateWithDuration:duration animations:^{
                    
                    self.microphoneView.frame = CGRectMake(0, 0, 100, 100);
                    self.microphoneView.center = self.view.center;
                    [self.view layoutIfNeeded];
                } completion:^(BOOL finished) {
                    //Start recording once the microphone icon is presented
                    if (!self.audioSessionManager.isRecording) {
                        [self startRecording];
                    }
                    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:10 options:0 animations:^{
                        [self.sendButtonBottomConstraint autoRemove];
                        [self.cancelButtonBottomConstraint autoRemove];
                        [self.view layoutIfNeeded];
                    } completion:nil];
                }];
            });
        });
    }];
}

#pragma - mark Private Methods

- (UIView *)blurredBackgroundView {
    if (!_blurredBackgroundView) {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            _blurredBackgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        } else {
            UIToolbar *toolbar = [[UIToolbar alloc] init];
            toolbar.barStyle = UIBarStyleDefault;
            _blurredBackgroundView = toolbar;
        }
    }
    return _blurredBackgroundView;
}

- (void)updateTime:(id)sender
{
    NSTimeInterval time = [self.audioSessionManager currentTimeRecordTime];
    time = round(time);
    NSUInteger minutes = (int)time / 60;
    NSUInteger seconds = (int)time % 60;
    
    self.timerLabel.text = [NSString stringWithFormat:@"%lu:%02ld",(unsigned long)minutes,seconds];
}

- (void)animateAwayViewsWithDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion
{
    CAShapeLayer *maskLayer = (CAShapeLayer *)self.blurredBackgroundView.layer.mask;
    CGPathRef oldPath = maskLayer.path;
    //Calculate new rect with same center but only 1 x 1
    CGRect newCircleRect = CGRectMake(CGRectGetMidX(self.view.bounds)-1, CGRectGetMidY(self.view.bounds)-1, 1, 1);
    CGPathRef newPath = [UIBezierPath bezierPathWithOvalInRect:newCircleRect].CGPath;
    
    CABasicAnimation* revealAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    revealAnimation.fromValue = (__bridge id)(oldPath);
    revealAnimation.toValue = (__bridge id)(newPath);
    revealAnimation.duration = duration;
    
    [self.blurredBackgroundView.layer.mask addAnimation:revealAnimation forKey:kOTRAudioRecordAnimatePath];
    
    ((CAShapeLayer *)self.blurredBackgroundView.layer.mask).path = newPath;
    
    [UIView animateWithDuration:duration animations:^{
        self.microphoneView.frame = CGRectMake(0, 0, 0, 0);
        self.microphoneView.center = self.view.center;
        [self.cancelButton removeFromSuperview];
        [self.view layoutIfNeeded];
    } completion:completion];
}

- (void)startRecording
{
    NSString *temporaryPath = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"%@.m4a",[[NSUUID UUID] UUIDString]];
    NSURL *url = [NSURL fileURLWithPath:[temporaryPath stringByAppendingPathComponent:fileName]];
    [self.audioSessionManager recordAudioToURL:url error:nil];
    [self.labelTimer invalidate];
    [self updateTime:nil];
    self.labelTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
}

- (void)stopRecording
{
    [self.labelTimer invalidate];
    self.labelTimer = nil;
    [self updateTime:nil];
    __block NSURL *url = [self.audioSessionManager currentRecorderURL];
    [self.audioSessionManager stopRecording];
    
    __block NSString *buddyUniqueId = self.buddy.uniqueId;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block OTRMessage *message = [[OTRMessage alloc] init];
        message.incoming = NO;
        message.buddyUniqueId = buddyUniqueId;
        
        __block OTRAudioItem *audioItem = [[OTRAudioItem alloc] init];
        audioItem.isIncoming = message.incoming;
        audioItem.filename = [[url absoluteString] lastPathComponent];
        
        AVURLAsset *audioAsset = [AVURLAsset assetWithURL:url];
        audioItem.timeLength = CMTimeGetSeconds(audioAsset.duration);
        
        message.mediaItemUniqueId = audioItem.uniqueId;
        
        //Copy from temporary directory to encrypted stroage
        NSString *encryptedPath = [OTRMediaFileManager pathForMediaItem:audioItem buddyUniqueId:buddyUniqueId];
        [[OTRMediaFileManager sharedInstance] copyDataFromFilePath:url.path
                                                   toEncryptedPath:encryptedPath
                                                   completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                                                        completion:^(NSError *error) {
                                                            [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                                                                [audioItem saveWithTransaction:transaction];
                                                                [message saveWithTransaction:transaction];
                                                            }];
                                                            
                                                            if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
                                                                
                                                                [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
                                                            }
                                                        }];
    });
}

#pragma - mark AutoLayout
- (void)updateViewConstraints
{
    if (!self.addedConstraints) {
        
        [self.blurredBackgroundView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        
        [self.timerLabel autoAlignAxis:ALAxisVertical toSameAxisOfView:self.microphoneImageView];
        // The numbers .68 and .56 were calculated from the original svg to find the center of the microphone
        [self.timerLabel autoConstrainAttribute:ALAttributeHorizontal toAttribute:ALAttributeHorizontal ofView:self.microphoneImageView withMultiplier:0.68];
        [self.timerLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.microphoneImageView withMultiplier:0.56];
        
        [self.microphoneImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.microphoneImageView.superview];
        [self.microphoneImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.microphoneImageView withMultiplier:self.microphoneRatio];
        [self.microphoneImageView autoCenterInSuperview];
        
        [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:5];
        [UIView autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
            [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:5];
        }];
        
        [self.cancelButton autoSetDimension:ALDimensionHeight toSize:30];
        [self.cancelButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.cancelButton];
        
        [self.sendButton autoAlignAxis:ALAxisVertical toSameAxisOfView:self.microphoneView];
        [UIView autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
            [self.sendButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.microphoneView];
        }];
        [self.sendButton autoSetDimension:ALDimensionHeight toSize:35];
        [self.sendButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.microphoneView];
        
        if (!self.sendButtonBottomConstraint) {
            self.sendButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:self.sendButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:5];
            [self.view addConstraint:self.sendButtonBottomConstraint];
        }
        
        if (!self.cancelButtonBottomConstraint) {
            self.cancelButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:self.cancelButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:5];
            [self.view addConstraint:self.cancelButtonBottomConstraint];
        }
        
        self.addedConstraints = YES;
    }
    [super updateViewConstraints];
}

#pragma - mark Button Methods

- (void)didPressCancel:(id)sender
{
    if (self.audioSessionManager.isRecording) {
        //Cancel
        NSURL *currentURL = [self.audioSessionManager currentRecorderURL];
        [self.audioSessionManager stopRecording];
        if([[NSFileManager defaultManager] fileExistsAtPath:currentURL.path]) {
            [[NSFileManager defaultManager] removeItemAtPath:currentURL.path error:nil];
        }
    }
    
    //Animate away the views
    [self animateAwayViewsWithDuration:0.5 completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)didPressSend:(id)sender
{
    if (self.audioSessionManager.isRecording) {
        [self stopRecording];
    }
    [self animateAwayViewsWithDuration:0.5 completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
    
}

@end
