//
//  OTRGroups.m
//  ChatSecure
//
//  Created by IN2 on 22/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBroadcastGroup.h"
#import "OTRAccount.h"

#import "Strings.h"

const struct OTRBroadcastGroupAttributes OTRBroadcastGroupAttributes = {
    .displayName = @"displayName",
    .composingMessageString = @"composingMessageString",
    .buddies = @"buddies"
};

const struct OTRBroadcastGroupRelationships OTRBroadcastGroupRelationships = {
    .accountUniqueId = @"accountUniqueId", 
};

const struct OTRBroadcastGroupEdges OTRBroadcastGroupEdges = {
    .account = @"account",
};

@implementation OTRBroadcastGroup


- (id)initWithBuddyArray:(NSMutableArray *)buddies;
{
    if (self = [super init])
    {
        self.buddies = [[NSMutableArray alloc]initWithArray:buddies];
        self.displayName = LIST_OF_DIFUSSION_STRING;
    }
    
    return self;
}

- (OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
}


- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.accountUniqueId) {
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRBroadcastGroupEdges.account
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[OTRAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = @[accountEdge];
    }
    
    
    return edges;
}





@end
