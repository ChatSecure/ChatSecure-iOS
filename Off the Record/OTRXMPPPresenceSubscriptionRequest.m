//
//  OTRXMPPPresenceSubscriptionRequest.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPPresenceSubscriptionRequest.h"
#import "OTRAccount.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRDatabaseManager.h"

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


#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder *)decoder // NSCoding deserialization
{
    if (self = [super initWithCoder:decoder]) {
        self.date = [decoder decodeObjectForKey:OTRXMPPPresenceSubscriptionRequestAttributes.date];
        self.jid = [decoder decodeObjectForKey:OTRXMPPPresenceSubscriptionRequestAttributes.jid];
        self.displayName = [decoder decodeObjectForKey:OTRXMPPPresenceSubscriptionRequestAttributes.displayName];
        
        self.accountUniqueId = [decoder decodeObjectForKey:OTRXMPPPresenceSubscriptionRequestRelationships.accountUniqueId];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder // NSCoding serialization
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:self.date forKey:OTRXMPPPresenceSubscriptionRequestAttributes.date];
    [encoder encodeObject:self.jid forKey:OTRXMPPPresenceSubscriptionRequestAttributes.jid];
    [encoder encodeObject:self.displayName forKey:OTRXMPPPresenceSubscriptionRequestAttributes.displayName];
    
    [encoder encodeObject:self.accountUniqueId forKey:OTRXMPPPresenceSubscriptionRequestRelationships.accountUniqueId];
}

#pragma - mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OTRXMPPPresenceSubscriptionRequest *copy = [super copyWithZone:zone];
    copy.date = [self.date copyWithZone:zone];
    copy.jid = [self.jid copyWithZone:zone];
    copy.displayName = [self.displayName copyWithZone:zone];
    
    return copy;
}

@end
