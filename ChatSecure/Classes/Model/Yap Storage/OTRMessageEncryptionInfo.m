//
//  OTRMessageEncryptionInfo.m
//  ChatSecure
//
//  Created by David Chiles on 11/10/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRMessageEncryptionInfo.h"

@implementation OTRMessageEncryptionInfo


- (nullable instancetype)initPlaintext {
    if (self = [super init]) {
        _messageSecurity = OTRMessageTransportSecurityPlaintext;
    }
    return self;
}

- (nullable instancetype)initWithOTRFingerprint:(nonnull NSData *)otrFingerprint {
    if (self = [super init]) {
        _messageSecurity = OTRMessageTransportSecurityOTR;
        _otrFingerprint = otrFingerprint;
    }
    return self;
}
- (nullable instancetype)initWithOMEMODevice:(nonnull NSString *)omemoDeviceYapKey collection:(nonnull NSString *)collection {
    if (self = [super init]) {
        _messageSecurity = OTRMessageTransportSecurityOMEMO;
        _omemoDeviceYapKey = omemoDeviceYapKey;
        _omemoDeviceYapCollection = collection;
    }
    return self;
}

@end
