//
//  OTRYapPushDevice.h
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapPushObject.h"
#import "OTRPushDevice.h"

extern const struct OTRPushDeviceEdges {
	__unsafe_unretained NSString *account;
} OTRPushDeviceEdges;

@interface OTRYapPushDevice : OTRYapPushObject <YapDatabaseRelationshipNode>

@property (nonatomic) OTRPushDeviceType osType;
@property (nonatomic, strong) NSString *osVersion;
@property (nonatomic, strong) NSString *deviceName;
@property (nonatomic, strong) NSString *pushToken;

@property (nonatomic, strong) NSString *accountUniqueId;

@end
