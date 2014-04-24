//
//  OTRPushObject.m
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPushObject.h"

@implementation OTRPushObject



#pragma - mark MTLJSONSerializing Methods

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"serverId":@"id"};
}

@end
