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
#import "OTRYapPushDevice.h"
#import "YapDatabaseRelationshipTransaction.h"

@implementation OTRYapPushAccount

- (NSString *) imageName {
    return @"ipad.png";
}

- (NSString *)providerName
{
    return @"ChatSecure Push";
}

//- (Class) protocolClass {
//    return [OTRPushManager class];
//}

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

- (NSArray *)allTokensWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSMutableArray *allTokens = [NSMutableArray array];
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRYapPushTokenEdges.account destinationKey:self.uniqueId collection:[OTRYapPushAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRYapPushToken *token = [OTRYapPushToken fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
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


@end
