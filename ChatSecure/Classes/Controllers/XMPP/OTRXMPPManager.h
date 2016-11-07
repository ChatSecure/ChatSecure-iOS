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
#import "OTRBuddy.h"
#import "OTRMessage.h"
#import "XMPPFramework.h"
#import "XMPPReconnect.h"
#import "XMPPRoster.h"
#import "XMPPCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPCapabilities.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "OTRProtocol.h"
#import "OTRXMPPBudyTimers.h"
#import "OTRCertificatePinning.h"
#import "OTRXMPPError.h"
#import "OTRConstants.h"

@class OTRXMPPAccount, OTRXMPPRoomManager;
@class OTROMEMOSignalCoordinator;

@interface OTRXMPPManager : NSObject <XMPPRosterDelegate, NSFetchedResultsControllerDelegate, OTRProtocol>

@property (nonatomic, strong, readonly) OTRXMPPAccount *account;

@property (nonatomic, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, readonly) OTRXMPPRoomManager *roomManager;
@property (nonatomic, strong) OTROMEMOSignalCoordinator *omemoSignalCoordinator;
@property (nonatomic, weak) id <PushControllerProtocol> pushController;


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
- (void) sendDeliveryReceiptForMessage:(OTRMessage*)message;

@end


/**
 This notification is sent every time there is a change in the login status and if it goes 'backwards' there
 should be an error or a user initiated disconnect.
 
 @{
 OTRXMPPOldLoginStatusKey : @(OTRLoginStatus)
 OTRXMPPNewLoginStatusKey : @(OTRLoginStatus)
 OTRXMPPLoginErrorKey     : NSError*
 }
 */
extern NSString *const OTRXMPPLoginStatusNotificationName;
extern NSString *const OTRXMPPOldLoginStatusKey;
extern NSString *const OTRXMPPNewLoginStatusKey;
extern NSString *const OTRXMPPLoginErrorKey;
extern NSString *const OTRXMPPRegisterSucceededNotificationName;
extern NSString *const OTRXMPPRegisterFailedNotificationName;
