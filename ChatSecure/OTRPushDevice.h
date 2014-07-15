//
//  OTRPushDevice.h
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPushObject.h"

typedef NS_ENUM(int, OTRPushDeviceType) {
    OTRPushDeviceTypeUnknown   = 0,
    OTRPushDeviceTypeAndroid   = 1,
    OTRPushDeviceTypeApple     = 2
};

@interface OTRPushDevice : OTRPushObject

@property (nonatomic) OTRPushDeviceType osType;
@property (nonatomic, strong) NSString *osVersion;
@property (nonatomic, strong) NSString *deviceName;
@property (nonatomic, strong) NSString *pushToken;


@end
