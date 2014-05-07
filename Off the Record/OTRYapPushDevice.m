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

@interface OTRYapPushDevice ()

@property (nonatomic, strong) OTRPushDevice *pushDevice;

@end

@implementation OTRYapPushDevice

- (id)initWithPushDevice:(OTRPushDevice *)pushDevice
{
    if (self = [self initWithUniqueId:[pushDevice.serverId stringValue]]) {
        self.pushDevice = pushDevice;
    }
    return self;
}

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
