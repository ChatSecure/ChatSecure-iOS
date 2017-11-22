//
//  OTRXMPPRoomYapStorage.h
//  ChatSecure
//
//  Created by David Chiles on 10/7/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import XMPPFramework;
@import YapDatabase;
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"

@class OTRXMPPRoomOccupant;

NS_ASSUME_NONNULL_BEGIN
@interface OTRXMPPRoomYapStorage : NSObject <XMPPRoomStorage>

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)databaseConnection
                              capabilities:(XMPPCapabilities*)capabilities;

- (id <OTRMessageProtocol>)lastMessageInRoom:(XMPPRoom *)room accountKey:(NSString *)accountKey;
@end
NS_ASSUME_NONNULL_END
