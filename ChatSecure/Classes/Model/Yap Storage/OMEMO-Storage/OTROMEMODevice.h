//
//  OTROMEMODevice.h
//  ChatSecure
//
//  Created by David Chiles on 9/14/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import <ChatSecureCore/ChatSecureCore.h>


/*
 *
 */
typedef NS_ENUM(NSUInteger, OMEMODeviceTrustLevel) {
    OMEMOTrustLevelUntrustedNew = 0,
    OMEMOTrustLevelUntrusted    = 1,
    OMEMOTrustLevelTrustedTofu  = 2,
    OMEMOTrustLevelTrustedUser  = 3
};

NS_ASSUME_NONNULL_BEGIN

@interface OTROMEMODevice : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong, readonly) NSString *parentKey;
@property (nonatomic, strong, readonly) NSString *parentCollection;

@property (nonatomic, strong, readonly) NSNumber *deviceId;

@property (nonatomic, strong, readonly, nullable) NSData *publicIdentityKeyData;

// First Time seing device list all trusted
// Any new devices after that are not trusted and require user input
@property (nonatomic, readonly) OMEMODeviceTrustLevel trustLevel;

@property (nonatomic, strong, readonly, nullable) NSDate *lastReceivedMessageDate;

/** OMEMOTrustLevelTrustedTofu || OMEMOTrustLevelTrustedUser */
- (BOOL) isTrusted;

- (nullable instancetype) initWithDeviceId:(NSNumber *)deviceId
                                trustLevel:(OMEMODeviceTrustLevel)trustLevel
                                 parentKey:(NSString *)parentKey
                          parentCollection:(NSString *)parentCollection
                     publicIdentityKeyData:(nullable NSData *)publicIdentityKeyData
                   lastReceivedMessageDate:(nullable NSDate *)lastReceivedMessageDate;


+ (void)enumerateDevicesForParentKey:(NSString *)key
                          collection:(NSString *)collection
                         transaction:(YapDatabaseReadTransaction *)transaction
                          usingBlock:(void (^)(OTROMEMODevice * _Nonnull device, BOOL * _Nonnull stop))block;

+ (NSArray <OTROMEMODevice *>*)allDevicesForParentKey:(NSString *)key
                                           collection:(NSString *)collection
                                          transaction:(YapDatabaseReadTransaction *)transaction;

+ (NSString *)yapKeyWithDeviceId:(NSNumber *)deviceId
                       parentKey:(NSString *)parentKey
                parentCollection:(NSString *)parentCollection;

@end

NS_ASSUME_NONNULL_END
