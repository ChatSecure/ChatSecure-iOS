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

@class OTRBuddy, OTRXMPPManager, OTRAccount, YapDatabaseConnection, OTRYapDatabaseObject;

@protocol OTRThreadOwner;

@protocol OTRMessagesViewControllerProtocol <NSObject>

- (void)receivedTextViewChangedNotification:(NSNotification *)notification;
- (void)setupAccessoryButtonsWithMessageState:(OTRKitMessageState)messageState;

@end

@interface OTRMessagesViewController : JSQMessagesViewController <UISplitViewControllerDelegate, OTRMessagesViewControllerProtocol, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) UIButton *microphoneButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *cameraButton;

- (void)setThreadKey:(NSString *)key collection:(NSString *)collection;

- (void)sendAudioFileURL:(NSURL *)url;

- (void)updateEncryptionState;

- (id<OTRThreadOwner>)threadObject;
- (OTRAccount *)account;
- (OTRXMPPManager *)xmppManager;

@end
