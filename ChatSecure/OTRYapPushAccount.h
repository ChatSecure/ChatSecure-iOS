//
//  OTRYapPushAccount.h
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPushAccount.h"
#import "YapDatabaseRelationshipNode.h"
#import "YapDatabaseTransaction.h"
#import "OTRYapDatabaseObject.h"

@interface OTRYapPushAccount : OTRYapDatabaseObject

@property (nonatomic, strong, readonly) OTRPushAccount *pushAccount;

- (id)initWithPushAccount:(OTRPushAccount *)pushAccount;

- (NSArray *)allTokensOwnedWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (NSArray *)allTokensRevievedWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (NSArray *)allDevicesWithTransaction:(YapDatabaseReadTransaction *)transaction;


+ (instancetype)currentAccountWithTransaction:(YapDatabaseReadTransaction *)transaction;
@end
