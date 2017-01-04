//
//  OTRXMPPBuddyManager.h
//  ChatSecure
//
//  Created by David Chiles on 1/6/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

@import XMPPFramework;

@class YapDatabaseConnection;
@protocol OTRProtocol;

@interface OTRXMPPBuddyManager : XMPPModule

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection; //This is always the single long lived read connection
@property (nonatomic, weak) id<OTRProtocol> protocol;

@end
