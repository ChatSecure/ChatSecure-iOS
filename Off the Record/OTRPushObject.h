//
//  OTRPushObject.h
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "MTLModel+NSCoding.h"
#import <MTLJSONAdapter.h>

@interface OTRPushObject : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSNumber *serverId;

@end
