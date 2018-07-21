//
//  OTRProtocol.h
//  Off the Record
//
//  Created by Chris Ballinger on 6/25/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
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

@class OTROutgoingMessage, OTRBuddy, OTRAccount;

typedef NS_ENUM(int, OTRProtocolType) {
    OTRProtocolTypeNone        = 0,
    OTRProtocolTypeXMPP        = 1,
    OTRProtocolTypeOscar       = 2 // deprecated
};

typedef NS_ENUM(NSInteger, OTRLoginStatus) {
    OTRLoginStatusDisconnected = 0,
    OTRLoginStatusDisconnecting,
    OTRLoginStatusConnecting,
    OTRLoginStatusConnected,
    OTRLoginStatusSecuring,
    OTRLoginStatusSecured,
    OTRLoginStatusAuthenticating,
    OTRLoginStatusAuthenticated
};

NS_ASSUME_NONNULL_BEGIN
@protocol OTRProtocol <NSObject>

/** Send a message immediately. Bypasses (and used by) the message queue. */
- (void) sendMessage:(OTROutgoingMessage*)message;

- (void) connect;
- (void) connectUserInitiated:(BOOL)userInitiated;

- (void) disconnect;
- (void) disconnectSocketOnly:(BOOL)socketOnly;
- (void) addBuddy:(OTRBuddy *)newBuddy;
- (void) addBuddies:(NSArray<OTRBuddy*> *)buddies;

- (void) removeBuddies:(NSArray<OTRBuddy*> *)buddies;
- (void) blockBuddies:(NSArray<OTRBuddy*> *)buddies;

- (instancetype) initWithAccount:(OTRAccount*)account;

@end

@protocol OTRXMPPProtocol <OTRProtocol>
- (void)sendChatState:(int)chatState withBuddy:(OTRBuddy *)buddy;
- (void) setDisplayName:(NSString *) newDisplayName forBuddy:(OTRBuddy *)buddy;
@end
NS_ASSUME_NONNULL_END
