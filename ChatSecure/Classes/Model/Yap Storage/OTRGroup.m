//
//  OTRGroups.m
//  ChatSecure
//
//  Created by IN2 on 22/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRGroup.h"
#import "OTRAccount.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRDatabaseManager.h"

#import "Strings.h"

const struct OTRGroupAttributes OTRGroupAttributes = {
    .displayName = @"groupName",
};

const struct OTRGroupRelationships OTRGroupRelationships = {
    .accountUniqueId = @"accountUniqueId", 
};

const struct OTRGroupEdges OTRGroupEdges = {
    .account = @"account",
};

@implementation OTRGroup


- (id)initWithGroupName:(NSString*) groupName
{
    if (self = [super init])
    {
        self.displayName = groupName;
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
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRGroupEdges.account
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[OTRAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = @[accountEdge];
    }
    
    
    return edges;
}



+ (instancetype)fetchGroupWithGroupName:(NSString *)name withAccountUniqueId:(NSString *)accountUniqueId transaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRGroup *finalGroup = nil;
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRGroupEdges.account destinationKey:accountUniqueId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRGroup * group = [transaction objectForKey:edge.sourceKey inCollection:[OTRGroup collection]];
        if ([group.displayName isEqualToString:name]) {
            *stop = YES;
            finalGroup = group;
        }
    }];
    
    return [finalGroup copy];
}





@end
