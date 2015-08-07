//
//  OTRXMPPPresenceSubscriptionRequest.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPPresenceSubscriptionRequest.h"
#import "OTRAccount.h"
@import YapDatabase;
#import "OTRDatabaseManager.h"
#import "OTRXMPPAccount.h"

const struct OTRXMPPPresenceSubscriptionRequestAttributes OTRXMPPPresenceSubscriptionRequestAttributes = {
	.date = @"date",
	.jid = @"jid",
	.displayName = @"displayName"
};

const struct OTRXMPPPresenceSubscriptionRequestRelationships OTRXMPPPresenceSubscriptionRequestRelationships = {
	.accountUniqueId = @"accountUniqueId"
};

const struct OTRXMPPPresenceSubscriptionRequestEdges OTRXMPPPresenceSubscriptionRequestEdges = {
	.account = @"account"
};

@implementation OTRXMPPPresenceSubscriptionRequest

- (id)init
{
    if (self = [super init]) {
        self.date = [NSDate date];
    }
    return self;
}

- (OTRXMPPAccount *)accountWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRXMPPAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
}


+ (instancetype)fetchPresenceSubscriptionRequestWithJID:(NSString *)jid accontUniqueId:(NSString *)accountUniqueId transaction:(YapDatabaseReadTransaction *)transaction
{
    __block id request = nil;
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRXMPPPresenceSubscriptionRequestEdges.account destinationKey:accountUniqueId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRXMPPPresenceSubscriptionRequest *edgeRequest = [OTRXMPPPresenceSubscriptionRequest fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if ([edgeRequest.jid isEqualToString:jid]) {
            request = edgeRequest;
            *stop = YES;
        }
    }];
    
    return request;
}


#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRXMPPPresenceSubscriptionRequestEdges.account
                                                                          destinationKey:self.accountUniqueId
                                                                              collection:[OTRAccount collection]
                                                                         nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
    
    return @[accountEdge];
}

@end
