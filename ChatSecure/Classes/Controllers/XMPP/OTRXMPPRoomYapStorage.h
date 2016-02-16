//
//  OTRXMPPRoomYapStorage.h
//  ChatSecure
//
//  Created by David Chiles on 10/7/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPRoom.h"
#import "YapDatabaseConnection.h"
#import "OTRMessage.h"

@interface OTRXMPPRoomYapStorage : NSObject <XMPPRoomStorage>

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)databaseConnection;

- (id <OTRMesssageProtocol>)lastMessageInRoom:(XMPPRoom *)room accountKey:(NSString *)accountKey;
@end
