//
//  OTRXMPPMessageYapStroage.h
//  ChatSecure
//
//  Created by David Chiles on 8/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "XMPPModule.h"
#import "YapDatabaseConnection.h"
@class XMPPMessage;

@protocol OTRXMPPMessageYapStroageProtocol <NSObject>

@required;
- (void)storeMessage:(XMPPMessage *)message stream:(XMPPStream *)stream incoming:(BOOL)incoming;

@end

@interface OTRXMPPMessageYapStroage : XMPPModule <OTRXMPPMessageYapStroageProtocol>

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)connection;

@end
