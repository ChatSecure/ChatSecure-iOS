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

@class OTRMessage, OTRBuddy, OTRAccount;

typedef NS_ENUM(int, OTRProtocolType) {
    OTRProtocolTypeNone        = 0,
    OTRProtocolTypeXMPP        = 1,
    OTRProtocolTypeOscar       = 2
};

typedef NS_ENUM(NSInteger, OTRProtocolConnectionStatus) {
    OTRProtocolConnectionStatusDisconnected,
    OTRProtocolConnectionStatusConnected,
    OTRProtocolConnectionStatusConnecting
};

@protocol OTRProtocol <NSObject>

- (OTRAccount *)account;
- (OTRProtocolConnectionStatus)connectionStatus;

- (void) sendMessage:(OTRMessage*)message;

- (void) connectWithPassword:(NSString *)password;
- (void) connectWithPassword:(NSString *)password userInitiated:(BOOL)userInitiated;

- (void) disconnect;
- (void) addBuddy:(OTRBuddy *)newBuddy;

- (void) removeBuddies:(NSArray *)buddies;
- (void) blockBuddies:(NSArray *)buddies;

- (id) initWithAccount:(OTRAccount*)account;

@end

@protocol OTRXMPPProtocol <OTRProtocol>
- (void)sendChatState:(int)chatState withBuddy:(OTRBuddy *)buddy;
- (void) setDisplayName:(NSString *) newDisplayName forBuddy:(OTRBuddy *)buddy;
@end