//
//  OTRStreamManagementYapStorage.h
//  ChatSecure
//
//  Created by David Chiles on 11/19/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPStreamManagement.h"

@class YapDatabaseConnection;

@interface OTRStreamManagementYapStorage : NSObject <XMPPStreamManagementStorage>

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)databaseConnection;

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;

@end
