//
//  OTRYapPushDevice.h
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPushDevice.h"
#import "YapDatabaseRelationshipNode.h"
#import "OTRYapDatabaseObject.h"

extern const struct OTRPushDeviceEdges {
	__unsafe_unretained NSString *account;
} OTRPushDeviceEdges;

@interface OTRYapPushDevice : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong, readonly) OTRPushDevice *pushDevice;

@property (nonatomic, strong) NSString *accountUniqueId;

- (id)initWithPushDevice:(OTRPushDevice *)pushDevice;

@end
