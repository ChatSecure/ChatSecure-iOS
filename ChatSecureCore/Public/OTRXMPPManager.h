//
//  OTRXMPPManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/7/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

@import Foundation;
@import UIKit;
@import XMPPFramework;
#import "OTRXMPPBuddy.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRProtocol.h"
#import "OTRConstants.h"
#import "OTRServerCapabilities.h"
#import "OTRXMPPRoomManager.h"

@class OTRXMPPAccount;
@class OTROMEMOSignalCoordinator;
@class DatabaseConnections;
@class XMPPPushModule, ServerCheck, FileTransferManager, MessageStorage;

NS_ASSUME_NONNULL_BEGIN
NS_SWIFT_NAME(XMPPManager)
@interface OTRXMPPManager : NSObject <XMPPRosterDelegate, XMPPStreamDelegate, NSFetchedResultsControllerDelegate, OTRProtocol>

@property (nonatomic, strong, readonly) OTRXMPPAccount *account;

@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) OTRXMPPRoomManager *roomManager;
@property (nonatomic, strong, nullable) OTROMEMOSignalCoordinator *omemoSignalCoordinator;
@property (nonatomic, strong, readonly) XMPPPushModule *xmppPushModule;
@property (nonatomic, strong, readonly) ServerCheck *serverCheck;
@property (nonatomic, strong, readonly) FileTransferManager *fileTransferManager;
@property (nonatomic, strong, readonly) MessageStorage *messageStorage;
@property (nonatomic, strong, readonly) DatabaseConnections *connections;

@property (atomic, readonly) OTRLoginStatus loginStatus;
/** Useful for showing error messages related to connection, like SSL certs. Only safe for access from main queue. */
@property (nonatomic, readonly, nullable) NSError *lastConnectionError;

/** Call this if you want to register a new account on a compatible server */
- (BOOL)startRegisteringNewAccount;


//Chat State
- (void)sendChatState:(OTRChatState)chatState withBuddyID:(NSString *)buddyUniqueId;
- (void)restartPausedChatStateTimerForBuddyObjectID:(NSString *)buddyUniqueId;
- (void)restartInactiveChatStateTimerForBuddyObjectID:(NSString *)buddyUniqueId;
- (void)invalidatePausedChatStateTimerForBuddyUniqueId:(NSString *)buddyUniqueId;
- (void)sendPausedChatState:(NSTimer *)timer;
- (void)sendInactiveChatState:(NSTimer *)timer;
- (NSTimer *)inactiveChatStateTimerForBuddyObjectID:(NSString *)buddyUniqueId;
- (NSTimer *)pausedChatStateTimerForBuddyObjectID:(NSString *)buddyUniqueId;

// Delivery receipts
- (void) sendDeliveryReceiptForMessage:(OTRIncomingMessage*)message;

/**
 This updates the avatar for this managers account. It is async and will call the completion block immediately if newImage is nil.
 The best way to check for changes is to listen for Yap Database changes on the account object. 
 The completion block is called once the image is uploaded and the server responds.
 */
- (void)setAvatar:(UIImage *)newImage completion:(void (^ _Nullable)(BOOL success))completion;

/** Force a vCard update (by manipulating pixel values in the avatar image)
 */
- (void)forcevCardUpdateWithCompletion:(void (^)(BOOL success))completion;

- (void)changePassword:(NSString *)newPassword completion:(void (^)(BOOL,NSError*))completion;

/** Will try to send a probe to fetch last seen. If buddy is still pendingApproval it will retry subscription request. */
- (void) sendPresenceProbeForBuddy:(OTRXMPPBuddy*)buddy;

/** Will send an away presence with your last idle timestamp */
- (void) goAway;

/** Will send an available presence */
- (void) goOnline;

/** Enqueues a message to be sent by message queue */
- (void) enqueueMessage:(id<OTRMessageProtocol>)message;

/** Enqueues an array of messages to be sent by message queue */
- (void) enqueueMessages:(NSArray<id<OTRMessageProtocol>>*)messages;

/** Add new buddy using JID (or return existing). If we have an incoming subscription request, answer that. Always add buddy to roster. @warn ⚠️ Opens implicit readwrite transaction. May block UI, or cause deadlocks if used within another transaction. */
- (OTRXMPPBuddy *)addToRosterWithJID:(XMPPJID *)jid
                         displayName:(nullable NSString *)displayName;
@end


NS_ASSUME_NONNULL_END
