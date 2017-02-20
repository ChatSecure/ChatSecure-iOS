//
//  OTRMessageEncryptionInfo.h
//  ChatSecure
//
//  Created by David Chiles on 11/10/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

@import Mantle;

// This enum reperesents all the ways a message can be transported.
typedef NS_ENUM(NSUInteger, OTRMessageTransportSecurity) {
    OTRMessageTransportSecurityPlaintext = 0,
    OTRMessageTransportSecurityPlaintextWithOTR = 3, //This was added later so we needed to maintain the initial raw value. This is opportunistic OTR, appending special whitespace.
    OTRMessageTransportSecurityOTR = 1,
    OTRMessageTransportSecurityOMEMO = 2
};

@interface OTRMessageEncryptionInfo : MTLModel

- (nullable instancetype) init NS_UNAVAILABLE;

- (nullable instancetype)initWithMessageSecurity:(OTRMessageTransportSecurity)messageSecurity;
- (nullable instancetype)initPlaintext;
- (nullable instancetype)initWithOTRFingerprint:(nonnull NSData *)otrFingerprint;
- (nullable instancetype)initWithOMEMODevice:(nonnull NSString *)omemoDeviceYapKey collection:(nonnull NSString*)collection;

@property (nonatomic, readonly) OTRMessageTransportSecurity messageSecurity;
@property (nonatomic, strong, nullable, readonly) NSString *omemoDeviceYapKey;
@property (nonatomic, strong, nullable, readonly) NSString *omemoDeviceYapCollection;
@property (nonatomic, strong, nullable, readonly) NSData *otrFingerprint;

@end
