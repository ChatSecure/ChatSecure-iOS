//
//  OTRXMPPMessageYapStroage.h
//  ChatSecure
//
//  Created by David Chiles on 8/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import XMPPFramework;
@import YapDatabase;
@class XMPPMessage;

@interface OTRXMPPMessageYapStroage : XMPPModule

@property (nonatomic, strong, nonnull) YapDatabaseConnection *databaseConnection;

- (_Nullable instancetype)initWithDatabaseConnection:(YapDatabaseConnection * _Nonnull )connection;

@end
