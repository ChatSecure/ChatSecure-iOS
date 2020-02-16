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
@import JSQMessagesViewController;

@class OTRBuddy, OTRXMPPManager, OTRXMPPRoom, OTRXMPPAccount, YapDatabaseConnection, OTRYapDatabaseObject, MessagesViewControllerState, DatabaseConnections;
@class SupplementaryViewHandler;

@protocol OTRThreadOwner,OTRMessageProtocol,JSQMessageData;

@protocol OTRMessagesViewControllerProtocol <NSObject>

- (void)receivedTextViewChangedNotification:( NSNotification * _Nonnull )notification;
- (void)didUpdateState;

@end

@interface OTRMessagesViewController : JSQMessagesViewController <OTRMessagesViewControllerProtocol, UIPopoverPresentationControllerDelegate>

@property (nonatomic, readonly, nullable) SupplementaryViewHandler *supplementaryViewHandler;
@property (nonatomic, readonly, nullable) DatabaseConnections *connections;
@property (nonatomic, strong, readonly, nullable) YapDatabaseConnection *uiConnection DEPRECATED_MSG_ATTRIBUTE("Use connections.ui instead");
@property (nonatomic, strong, readonly, nullable) YapDatabaseConnection *readConnection DEPRECATED_MSG_ATTRIBUTE("Use connections.read instead");
@property (nonatomic, strong, readonly, nullable) YapDatabaseConnection *writeConnection DEPRECATED_MSG_ATTRIBUTE("Use connections.write instead");
@property (nonatomic, strong, nullable) NSString *threadKey;
@property (nonatomic, strong, nullable) NSString *threadCollection;
@property (nonatomic, strong, nullable) UIButton *microphoneButton;
@property (nonatomic, strong, nullable) UIButton *sendButton;
@property (nonatomic, strong, nullable) UIButton *cameraButton;

@property (nonatomic, strong, nonnull, readonly) MessagesViewControllerState *state;
@property (nonatomic) BOOL automaticURLFetchingDisabled;

- (void)setThreadKey:(nullable NSString *)key collection:(nullable NSString *)collection;
- (void)sendAudioFileURL:(nonnull NSURL *)url;
- (void)sendImageFilePath:(nonnull NSString *)filePath asJPEG:(BOOL)asJPEG shouldResize:(BOOL)shouldResize;

- (void)updateEncryptionState;

- (nullable UIBarButtonItem *)rightBarButtonItem;

- (void)infoButtonPressed:(nullable id)sender;
- (void)newDeviceButtonPressed:(nonnull NSString *)buddyUniqueId;

- (nullable id<OTRThreadOwner>)threadObjectWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable OTRXMPPAccount *)accountWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable OTRXMPPManager *)xmppManagerWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable id <OTRMessageProtocol,JSQMessageData>)messageAtIndexPath:(nonnull NSIndexPath *)indexPath;

/** Group chat support */
- (nullable OTRXMPPRoom *)roomWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (BOOL) isGroupChat;


/** Buddies is array of OTRBuddy.uniqueId */
- (void)setupWithBuddies:(nonnull NSArray<NSString *> *)buddies accountId:(nonnull NSString *)accountId name:(nullable NSString *)name;


/** This is called on every key stroke so be careful here. Used in subclasses*/
- (void)isTyping;

/** This is called once the text view has no text or is cleared after an update*/
- (void)didFinishTyping;

/** Currently uses clock for queued, and checkmark for delivered. */
- (nullable NSAttributedString*) deliveryStatusStringForMessage:(nonnull id<OTRMessageProtocol>)message;

/** override this method to customize what should be shown at the beginning of the message status */
- (nullable NSAttributedString *) encryptionStatusStringForMessage:(nonnull id<OTRMessageProtocol>)message;

@end
