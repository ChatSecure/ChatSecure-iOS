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

NS_ASSUME_NONNULL_BEGIN
@interface OTRXMPPRoomManager : XMPPModule

@property (nonatomic, strong, readonly) XMPPBookmarksModule *bookmarksModule;
@property (nonatomic, strong, readonly, nullable)  NSArray<NSString*> *conferenceServicesJID;
@property (nonatomic, strong, nullable) YapDatabaseConnection * databaseConnection;

/** All room joining should go through this method. This ensures the delegates are setup properly and database is in sync. Returns OTRThreadOwner.threadIdentifier */
- (nullable NSString *)joinRoom:(XMPPJID *)jid
                   withNickname:(nullable NSString *)name
                        subject:(nullable NSString *)subject
                       password:(nullable NSString*)password;

- (void)leaveRoom:(XMPPJID *)jid;
- (nullable XMPPRoom*) roomForJID:(XMPPJID*)jid;

/** Returns OTRThreadOwner.threadIdentifier. buddiesArray is array of OTRBuddy.uniqueId */
- (nullable NSString *)startGroupChatWithBuddies:(nullable NSArray <NSString *>*)buddiesArray
                                         roomJID:(XMPPJID *)roomName
                                        nickname:(nullable NSString *)name
                                         subject:(nullable NSString *)subject;

- (void)inviteBuddies:(nullable NSArray<NSString *>*)buddyUniqueIds
               toRoom:(XMPPRoom*)room;

@end

@interface XMPPRoom(RoomManager)
/** Creates and sends XMPPMessage stanza from roomMessage */
- (void) sendRoomMessage:( OTRXMPPRoomMessage *)roomMessage;
@end
NS_ASSUME_NONNULL_END
