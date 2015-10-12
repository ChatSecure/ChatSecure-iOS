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

@property (nonatomic, strong, readonly) NSArray * conferenceServicesJID;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;

- (void)joinRoom:(XMPPJID *)jid withNickname:(NSString *)name;

@end
