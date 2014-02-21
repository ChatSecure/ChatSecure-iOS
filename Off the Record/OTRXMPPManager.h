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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "XMPPFramework.h"
#import "XMPPReconnect.h"
#import "XMPPRoster.h"
#import "XMPPCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPCapabilities.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "OTRCodec.h"
#import "OTRProtocol.h"
#import "OTRManagedXMPPAccount.h"
#import "OTRManagedBuddy.h"
#import "OTRXMPPBudyTimers.h"
#import "OTRCertificatePinning.h"

@class OTRRosterStorage;

@interface OTRXMPPManager : NSObject <XMPPRosterDelegate, NSFetchedResultsControllerDelegate, OTRProtocol, OTRCertificatePinningDelegate>

@property (nonatomic, readonly) XMPPStream *xmppStream;
@property (nonatomic, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, readonly) OTRRosterStorage *xmppRosterStorage;
@property (nonatomic, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, readonly) OTRCertificatePinning * certificatePinningModule;
@property (nonatomic, readonly) BOOL isXmppConnected;

- (BOOL)connectWithJID:(NSString*) myJID password:(NSString*)myPassword;
- (void)disconnect;

- (NSString*)accountName;


//Chat State
- (void)sendChatState:(OTRChatState)chatState withBuddyID:(NSManagedObjectID *)managedBuddyObjectID;
- (void)restartPausedChatStateTimerForBuddyObjectID:(NSManagedObjectID *)managedBuddyObjectID;
- (void)restartInactiveChatStateTimerForBuddyObjectID:(NSManagedObjectID *)managedBuddyObjectID;
- (void)sendPausedChatState:(NSTimer *)timer;
- (void)sendInactiveChatState:(NSTimer *)timer;
- (NSTimer *)inactiveChatStateTimerForBuddyObjectID:(NSManagedObjectID *)managedBuddyObjectID;
- (NSTimer *)pausedChatStateTimerForBuddyObjectID:(NSManagedObjectID *)managedBuddyObjectID;

@end
