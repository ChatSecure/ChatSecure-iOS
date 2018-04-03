//
//  OTRMessageEncryptionInfo.h
//  ChatSecure
//
//  Created by David Chiles on 11/10/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

@import Mantle;

NS_ASSUME_NONNULL_BEGIN

// This enum reperesents all the ways a message can be transported.
typedef NS_ENUM(NSUInteger, OTRMessageTransportSecurity) {
    OTRMessageTransportSecurityInvalid = 4, // //This was added later so we needed to maintain the initial raw value of other values.
    OTRMessageTransportSecurityPlaintext = 0,
    OTRMessageTransportSecurityPlaintextWithOTR = 3, //This was added later so we needed to maintain the initial raw value. This is opportunistic OTR, appending special whitespace.
    OTRMessageTransportSecurityOTR = 1,
    OTRMessageTransportSecurityOMEMO = 2
};


@interface OTRMessageEncryptionInfo : MTLModel

- (instancetype) init NS_UNAVAILABLE;

- (instancetype)initWithMessageSecurity:(OTRMessageTransportSecurity)messageSecurity;
- (instancetype)initPlaintext;
- (instancetype)initWithOTRFingerprint:(NSData *)otrFingerprint;
- (instancetype)initWithOMEMODevice:(NSString *)omemoDeviceYapKey collection:(NSString*)collection;

@property (nonatomic, readonly) OTRMessageTransportSecurity messageSecurity;
@property (nonatomic, strong, nullable, readonly) NSString *omemoDeviceYapKey;
@property (nonatomic, strong, nullable, readonly) NSString *omemoDeviceYapCollection;
@property (nonatomic, strong, nullable, readonly) NSData *otrFingerprint;

@end
NS_ASSUME_NONNULL_END
