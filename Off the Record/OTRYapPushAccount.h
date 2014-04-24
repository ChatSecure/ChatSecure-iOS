//
//  OTRYapPushAccount.h
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapPushObject.h"

@interface OTRYapPushAccount : OTRYapPushObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *email;


- (NSArray *)allTokensWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (NSArray *)allDevicesWithTransaction:(YapDatabaseReadTransaction *)transaction;

+ (OTRYapPushAccount *) activeAccountWithTransaction:(YapDatabaseReadTransaction *)transaction;

@end
