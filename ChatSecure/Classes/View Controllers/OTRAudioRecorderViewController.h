//
//  OTRAudioRecorderViewController.h
//  ChatSecure
//
//  Created by David Chiles on 2/11/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRBuddy, OTRAudioRecorderViewController;

@protocol OTRAudioRecorderViewControllerDelegate <NSObject>

- (void)audioRecorder:(OTRAudioRecorderViewController *)audioRecorder gotAudioURL:(NSURL *)url;

@end

@interface OTRAudioRecorderViewController : UIViewController

@property (nonatomic, weak) id <OTRAudioRecorderViewControllerDelegate> delegate;

- (void)showAudioRecorderFromViewController:(UIViewController *)viewController animated:(BOOL)animated fromMicrophoneRectInWindow:(CGRect)rectInWindow;


@end
