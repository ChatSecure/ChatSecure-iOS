//
//  OTRMessagesViewController.h
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

#import "OTRBuddy.h"
#import "OTROutgoingMessage.h"
@import OTRKit;
@import JSQMessagesViewController;

@class OTRBuddy, OTRXMPPManager, OTRXMPPRoom, OTRAccount, YapDatabaseConnection, OTRYapDatabaseObject, MessagesViewControllerState;

@protocol OTRThreadOwner,OTRMessageProtocol,JSQMessageData;

@protocol OTRMessagesViewControllerProtocol <NSObject>

- (void)receivedTextViewChangedNotification:( NSNotification * _Nonnull )notification;
- (void)didUpdateState;

@end

@interface OTRMessagesViewController : JSQMessagesViewController <OTRMessagesViewControllerProtocol, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong, nonnull) YapDatabaseConnection *readOnlyDatabaseConnection;
@property (nonatomic, strong, nonnull) YapDatabaseConnection *readWriteDatabaseConnection;
@property (nonatomic, strong, nullable) NSString *threadKey;
@property (nonatomic, strong, nullable) NSString *threadCollection;
@property (nonatomic, strong, nullable) UIButton *microphoneButton;
@property (nonatomic, strong, nullable) UIButton *sendButton;
@property (nonatomic, strong, nullable) UIButton *cameraButton;

@property (nonatomic, strong, nonnull, readonly) MessagesViewControllerState *state;

- (void)setupWithBuddies:(nonnull NSArray<NSString *> *)buddies accountId:(nonnull NSString *)accountId name:(nullable NSString *)name;

- (void)setThreadKey:(nullable NSString *)key collection:(nullable NSString *)collection;
- (void)sendAudioFileURL:(nonnull NSURL *)url;
- (void)sendImageFilePath:(nonnull NSString *)filePath asJPEG:(BOOL)asJPEG shouldResize:(BOOL)shouldResize;

- (void)updateEncryptionState;

- (nullable UIBarButtonItem *)rightBarButtonItem;

- (void)infoButtonPressed:(nullable id)sender;


- (nullable id<OTRThreadOwner>)threadObjectWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable OTRAccount *)accountWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable OTRXMPPManager *)xmppManagerWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable id <OTRMessageProtocol,JSQMessageData>)messageAtIndexPath:(nonnull NSIndexPath *)indexPath;

/** Group chat support */
- (nullable OTRXMPPRoom *)roomWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (BOOL) isGroupChat;

/** This is called on every key stroke so be careful here. Used in subclasses*/
- (void)isTyping;

/** This is called once the text view has no text or is cleared after an update*/
- (void)didFinishTyping;

/** Currently uses clock for queued, and checkmark for delivered. */
- (nullable NSAttributedString*) deliveryStatusStringForMessage:(nonnull id<OTRMessageProtocol>)message;

/** override this method to customize what should be shown at the beginning of the message status */
- (nullable NSAttributedString *) encryptionStatusStringForMessage:(nonnull id<OTRMessageProtocol>)message;

@end
