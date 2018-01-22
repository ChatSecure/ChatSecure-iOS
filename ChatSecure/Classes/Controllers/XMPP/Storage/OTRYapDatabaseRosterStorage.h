//
//  OTRYapDatabaseRosterStorage.h
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import XMPPFramework;
@import YapDatabase;
#import "OTRXMPPBuddy.h"

@interface OTRYapDatabaseRosterStorage : NSObject <XMPPRosterStorage>

@property (nonatomic, strong, readonly, nonnull) YapDatabaseConnection *connection;

- (nullable OTRXMPPBuddy *)fetchBuddyWithJID:(nonnull XMPPJID *)jid stream:(nonnull XMPPStream *)stream transaction:(nonnull YapDatabaseReadTransaction *)transaction;

@end
