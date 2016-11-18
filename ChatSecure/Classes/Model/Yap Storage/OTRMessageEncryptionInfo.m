//
//  OTRMessageEncryptionInfo.m
//  ChatSecure
//
//  Created by David Chiles on 11/10/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRMessageEncryptionInfo.h"

@implementation OTRMessageEncryptionInfo


- (nullable instancetype)initWithMessageSecurity:(OTRMessageTransportSecurity)messageSecurity
{
    if (self = [super init]) {
        _messageSecurity = messageSecurity;
    }
    return self;
}

- (nullable instancetype)initPlaintext {
    return [self initWithMessageSecurity:OTRMessageTransportSecurityPlaintext];
}

- (nullable instancetype)initWithOTRFingerprint:(nonnull NSData *)otrFingerprint {
    if (self = [self initWithMessageSecurity:OTRMessageTransportSecurityOTR]) {
        _otrFingerprint = otrFingerprint;
    }
    return self;
}
- (nullable instancetype)initWithOMEMODevice:(nonnull NSString *)omemoDeviceYapKey collection:(nonnull NSString *)collection {
    if (self = [self initWithMessageSecurity:OTRMessageTransportSecurityOMEMO]) {
        _omemoDeviceYapKey = omemoDeviceYapKey;
        _omemoDeviceYapCollection = collection;
    }
    return self;
}

@end
