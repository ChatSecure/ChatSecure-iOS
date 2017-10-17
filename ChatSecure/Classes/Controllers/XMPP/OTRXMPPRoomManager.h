//
//  OTRXMPPRoomManager.h
//  ChatSecure
//
//  Created by David Chiles on 10/9/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import XMPPFramework;
@import YapDatabase;

@class OTRXMPPRoomMessage;
@class OTRXMPPRoomOccupant;

@interface OTRXMPPRoomManager : XMPPModule

@property (nonatomic, strong, readonly)  NSArray * _Nullable conferenceServicesJID;
@property (nonatomic, strong) YapDatabaseConnection * _Nullable databaseConnection;

/** All room creation and joining should go through this method. This ensures the delegates are setup properly and database is in sync */
- (nullable NSString *)joinRoom:(nonnull XMPPJID *)jid withNickname:(nonnull NSString *)name subject:(nullable NSString *)subject password:(nullable NSString*)password;

- (void)leaveRoom:(nonnull XMPPJID *)jid;
- (nullable XMPPRoom*) roomForJID:(nonnull XMPPJID*)jid;

- (nullable NSString *)startGroupChatWithBuddies:(nullable NSArray <NSString *>*)buddiesArray roomJID:(nonnull XMPPJID *)roomName nickname:(nonnull NSString *)name subject:(nullable NSString *)subject;

- (void)inviteBuddies:(nullable NSArray<NSString *>*)buddyUniqueIds toRoom:(nonnull XMPPRoom*)room;
- (OTRXMPPRoomOccupant * _Nullable) roomOccupantForJID:(nullable NSString *)jid realJID:(nullable NSString *)realJID inRoom:(nonnull NSString *)roomJID;

@end

@interface XMPPRoom(RoomManager)
/** Creates and sends XMPPMessage stanza from roomMessage */
- (void) sendRoomMessage:(nonnull OTRXMPPRoomMessage *)roomMessage;
@end
