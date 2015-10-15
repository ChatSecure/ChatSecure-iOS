//
//  OTRXMPPRoomManager.h
//  ChatSecure
//
//  Created by David Chiles on 10/9/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPModule.h"
@class XMPPJID, YapDatabaseConnection;

@interface OTRXMPPRoomManager : XMPPModule

@property (nonatomic, strong, readonly)  NSArray * _Nullable conferenceServicesJID;
@property (nonatomic, strong) YapDatabaseConnection * _Nullable databaseConnection;

- (nullable NSString *)joinRoom:(nonnull XMPPJID *)jid withNickname:(nonnull NSString *)name;

- (nullable NSString *)startGroupChatWithBuddies:(nullable NSArray <NSString *>*)buddiesArray roomJID:(nonnull XMPPJID *)roomName nickname:(nonnull NSString *)name;

@end
