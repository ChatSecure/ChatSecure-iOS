//
//  OTRAudioRecorderViewController.h
//  ChatSecure
//
//  Created by David Chiles on 2/11/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRBuddy;

@interface OTRAudioRecorderViewController : UIViewController

- (instancetype)initWithBuddy:(OTRBuddy *)buddy;

- (void)showAudioRecorderFromViewController:(UIViewController *)viewController animated:(BOOL)animated fromMicrophoneRectInWindow:(CGRect)rectInWindow;


@end
