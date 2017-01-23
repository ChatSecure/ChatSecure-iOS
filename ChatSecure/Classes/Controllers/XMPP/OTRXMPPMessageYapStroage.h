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

NS_ASSUME_NONNULL_BEGIN
@interface OTRXMPPMessageYapStroage : XMPPModule

@property (nonatomic, strong, readonly) YapDatabaseConnection *databaseConnection;
@property (nonatomic, readonly) dispatch_queue_t moduleDelegateQueue;

/** This connection is only used for readWrites */
- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)databaseConnection;

@end
NS_ASSUME_NONNULL_END
