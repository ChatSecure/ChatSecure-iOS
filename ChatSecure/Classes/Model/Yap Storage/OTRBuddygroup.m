//
//  OTRXMPPBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyGroup.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRDatabaseManager.h"
#import "OTRBuddy.h"
#import "OTRGroup.h"

const struct OTRBuddyGroupAttributes OTRBuddyGroupAttributes = {
};

const struct OTRBuddyGroupRelationships OTRBuddyGroupRelationships = {
    .groupUniqueId = @"groupUniqueId",
    .buddyUniqueId = @"buddyUnqiueId",
};

const struct OTRBuddyGroupEdges OTRBuddyGroupEdges = {
    .buddy = @"buddy",
    .group = @"group"
};



@implementation OTRBuddyGroup

- (id)init
{
    if (self = [super init]) {
       
    }
    return self;
}



+ (instancetype)fetchBuddyGroupWithBuddyUniqueId:(NSString *)buddyUniqueId withGroupUniqueId:(NSString *)groupUniqueId transaction:(YapDatabaseReadTransaction *)transaction;
{
    __block OTRBuddyGroup *finalBuddyGroup = nil;
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRBuddyGroupEdges.group destinationKey:groupUniqueId collection:[OTRGroup collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRBuddyGroup * buddy = [transaction objectForKey:edge.sourceKey inCollection:[OTRBuddyGroup collection]];
        if([buddy.buddyUniqueId isEqualToString:buddyUniqueId]) {
            *stop = YES;
            finalBuddyGroup = buddy;
        }
        
    }];
    
    return [finalBuddyGroup copy];
}


#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.groupUniqueId) {
        YapDatabaseRelationshipEdge *groupEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRBuddyGroupEdges.group
                                                                              destinationKey:self.groupUniqueId
                                                                                  collection:[OTRGroup collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = @[groupEdge];
    }
    
    
    return edges;
}


@end
