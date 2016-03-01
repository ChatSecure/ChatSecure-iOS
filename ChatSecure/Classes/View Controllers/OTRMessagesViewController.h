//
//  OTRMessagesViewController.h
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "OTRBuddy.h"
@import OTRKit;
@import JSQMessagesViewController;

@class OTRBuddy, OTRXMPPManager, OTRAccount, YapDatabaseConnection, OTRYapDatabaseObject, MessagesViewControllerState;

@protocol OTRThreadOwner,OTRMesssageProtocol,JSQMessageData;

@protocol OTRMessagesViewControllerProtocol <NSObject>

- (void)receivedTextViewChangedNotification:(NSNotification *)notification;
- (void)didUpdateState;

@end

@interface OTRMessagesViewController : JSQMessagesViewController <OTRMessagesViewControllerProtocol, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) NSString *threadKey;
@property (nonatomic, strong) NSString *threadCollection;
@property (nonatomic, strong) UIButton *microphoneButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *cameraButton;

@property (nonatomic, strong, readonly) MessagesViewControllerState *state;

- (void)setThreadKey:(NSString *)key collection:(NSString *)collection;
- (void)sendAudioFileURL:(NSURL *)url;
- (void)sendImageFilePath:(NSString *)filePath asJPEG:(BOOL)asJPEG shouldResize:(BOOL)shouldResize;

- (void)updateEncryptionState;

- (UIBarButtonItem *)rightBarButtonItem;

- (id<OTRThreadOwner>)threadObject;
- (OTRAccount *)account;
- (OTRXMPPManager *)xmppManager;
- (id <OTRMesssageProtocol,JSQMessageData>)messageAtIndexPath:(NSIndexPath *)indexPath;

@end
