//
//  OTRYapPushTokenSent.m
//  Off the Record
//
//  Created by David Chiles on 5/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapPushTokenOwned.h"

@implementation OTRYapPushTokenOwned

+ (instancetype)unusedPushTokenWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRYapPushTokenOwned *pushToken = nil;
    [transaction enumerateKeysAndObjectsInCollection:[self collection] usingBlock:^(NSString *key, OTRYapPushTokenOwned *token, BOOL *stop) {
        if (![token.buddyUniqueId length]) {
            pushToken = token;
            *stop = YES;
        }
        
    }];
    return pushToken;
}

@end
