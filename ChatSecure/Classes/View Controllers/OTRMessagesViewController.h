//
//  OTRMessagesViewController.h
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JSQMessagesViewController.h"
#import "OTRKit.h"

@class OTRBuddy, OTRXMPPManager, OTRAccount;

@protocol OTRMessagesViewControllerProtocol <NSObject>

- (void)receivedTextViewChangedNotification:(NSNotification *)notification;
- (void)setupAccessoryButtonsWithMessageState:(OTRKitMessageState)messageState;

@end

@interface OTRMessagesViewController : JSQMessagesViewController <UISplitViewControllerDelegate, OTRMessagesViewControllerProtocol, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) OTRBuddy *buddy;
@property (nonatomic, strong, readonly) OTRAccount *account;
@property (nonatomic, weak, readonly) OTRXMPPManager *xmppManager;

@property (nonatomic, strong) UIButton *microphoneButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *cameraButton;

-(void)sendAudioFileURL:(NSURL *)url;

@end
