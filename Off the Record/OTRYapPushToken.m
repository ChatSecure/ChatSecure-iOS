//
//  OTRYapPushToken.m
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapPushToken.h"
#import "OTRBuddy.h"
#import "OTRYapPushAccount.h"

const struct OTRYapPushTokenEdges OTRYapPushTokenEdges = {
	.account = @"account",
    .buddy = @"buddy"
};

@implementation OTRYapPushToken

#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = [NSArray array];
    if (self.accountUniqueId) {
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRYapPushTokenEdges.account
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[OTRYapPushAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = [edges arrayByAddingObject:accountEdge];
    }
    
    if (self.buddyUniqueId) {
        YapDatabaseRelationshipEdge *buddyEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRYapPushTokenEdges.buddy
                                                                            destinationKey:self.buddyUniqueId
                                                                                collection:[OTRBuddy collection]
                                                                           nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = [edges arrayByAddingObject:buddyEdge];
    }
    
    
    return edges;
}

#pragma - mark Class Methods

+ (OTRYapPushToken *)tokenWithTokenString:(NSString *)tokenString transaction:(YapDatabaseReadTransaction *)transaction
{
    NSArray *allKeys = [transaction allKeysInCollection:[OTRYapPushToken collection]];
    
    __block OTRYapPushToken *resultToken = nil;
    
    [transaction enumerateObjectsForKeys:allKeys inCollection:[OTRYapPushToken collection] unorderedUsingBlock:^(NSUInteger keyIndex, OTRYapPushToken *token, BOOL *stop) {
        if ([token.token isEqualToString:tokenString]) {
            
            resultToken = token;
            *stop = YES;
        }
    }];
    
    return resultToken;
}

@end
