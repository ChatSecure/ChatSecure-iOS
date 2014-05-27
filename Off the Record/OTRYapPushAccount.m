//
//  OTRYapPushAccount.m
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapPushAccount.h"
#import "OTRDatabaseManager.h"
#import "OTRYapPushToken.h"
#import "OTRYapPushTokenReceived.h"
#import "OTRYapPushTokenOwned.h"
#import "OTRYapPushDevice.h"
#import "YapDatabaseRelationshipTransaction.h"

@interface OTRYapPushAccount ()

@property (nonatomic, strong)OTRPushAccount *pushAccount;

@end

@implementation OTRYapPushAccount

- (id)initWithPushAccount:(OTRPushAccount *)pushAccount
{
    if (self = [self initWithUniqueId:[pushAccount.serverId stringValue]]) {
        self.pushAccount = pushAccount;
    }
    return self;
}

+ (OTRYapPushAccount *) activeAccountWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSArray *allKeys = [transaction allKeysInCollection:[OTRYapPushAccount collection]];
    NSString *firstKey = [allKeys firstObject];
    OTRYapPushAccount *account = nil;
    if ([firstKey length]) {
        account = [transaction objectForKey:firstKey inCollection:[OTRYapPushAccount collection]];
    }
    
    return account;
}

- (NSArray *)allTokensOwnedWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSMutableArray *allTokens = [NSMutableArray array];
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRYapPushTokenEdges.account destinationKey:self.uniqueId collection:[OTRYapPushTokenOwned collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRYapPushTokenOwned *token = [OTRYapPushTokenOwned fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        [allTokens addObject:token];
    }];
    return [allTokens copy];
}

- (NSArray *)allTokensRevievedWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSMutableArray *allTokens = [NSMutableArray array];
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRYapPushTokenEdges.account destinationKey:self.uniqueId collection:[OTRYapPushTokenReceived collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRYapPushTokenReceived *token = [OTRYapPushTokenReceived fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        [allTokens addObject:token];
    }];
    return [allTokens copy];
}

- (NSArray *)allDevicesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSMutableArray *allDevices = [NSMutableArray array];
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRPushDeviceEdges.account destinationKey:self.uniqueId collection:[OTRYapPushDevice collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRYapPushDevice *token = [OTRYapPushDevice fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        [allDevices addObject:token];
    }];
    return [allDevices copy];
}

+ (instancetype)currentAccountWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSArray *keys = [transaction allKeysInCollection:[self collection]];
    return [transaction objectForKey:[keys firstObject] inCollection:[self collection]];
}

@end
