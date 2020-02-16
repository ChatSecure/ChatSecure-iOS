//
//  OTRStreamManagementYapStorage.h
//  ChatSecure
//
//  Created by David Chiles on 11/19/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import XMPPFramework;

@class YapDatabaseConnection;

NS_ASSUME_NONNULL_BEGIN
@interface OTRStreamManagementYapStorage : NSObject <XMPPStreamManagementStorage>

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)databaseConnection;

@property (nonatomic, strong, readonly) YapDatabaseConnection *databaseConnection;

@end
NS_ASSUME_NONNULL_END
