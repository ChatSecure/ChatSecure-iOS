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

@interface OTRYapPushToken ()

@property (nonatomic, strong) OTRPushToken *pushToken;

@end

@implementation OTRYapPushToken


- (id)initWithPushToken:(OTRPushToken *)pushToken
{
    if (self = [self initWithUniqueId:pushToken.token]) {
        self.pushToken = pushToken;
    }
    return self;
}

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

+ (instancetype)tokenWithTokenString:(NSString *)tokenString transaction:(YapDatabaseReadTransaction *)transaction
{
    return [transaction objectForKey:tokenString inCollection:[self collection]];
}

@end
