//
//  OTRPushDevice.m
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPushDevice.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"

@implementation OTRPushDevice

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super JSONKeyPathsByPropertyKey]];
    
    [dict addEntriesFromDictionary:@{@"osType":@"os_type",
                                    @"osVersion":@"os_version",
                                    @"deviceName":@"device_name",
                                     @"pushToken":@"push_token"}];
    
    return [dict copy];
}

+ (NSValueTransformer *)osTypeJSONTransformer {
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
                                                                           @"iOS": @(OTRPushDeviceTypeApple),
                                                                           @"android": @(OTRPushDeviceTypeAndroid)
                                                                           }];
}

@end
