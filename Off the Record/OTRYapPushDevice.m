//
//  OTRYapPushDevice.m
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapPushDevice.h"
#import "OTRYapPushDevice.h"
#import "OTRYapPushAccount.h"

const struct OTRPushDeviceEdges OTRPushDeviceEdges = {
	.account = @"account",
};

@implementation OTRYapPushDevice

#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.accountUniqueId) {
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRPushDeviceEdges.account
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[OTRYapPushAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = @[accountEdge];
    }
    
    
    return edges;
}


@end
