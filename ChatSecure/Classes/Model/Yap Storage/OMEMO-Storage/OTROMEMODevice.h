//
//  OTROMEMODevice.h
//  ChatSecure
//
//  Created by David Chiles on 9/14/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"

/*
 *
 */
typedef NS_ENUM(NSUInteger, OMEMOTrustLevel) {
    OMEMOTrustLevelUntrustedNew = 0,
    OMEMOTrustLevelUntrusted    = 1,
    OMEMOTrustLevelTrustedTofu  = 2,
    OMEMOTrustLevelTrustedUser  = 3,
    /** If the device has been removed from the server */
    OMEMOTrustLevelRemoved  = 4,
};

NS_ASSUME_NONNULL_BEGIN

@interface OTROMEMODevice : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong, readonly) NSString *parentKey;
@property (nonatomic, strong, readonly) NSString *parentCollection;

@property (nonatomic, strong, readonly) NSNumber *deviceId;

@property (nonatomic, strong, readwrite, nullable) NSData *publicIdentityKeyData;

/** returns hex value of publicIdentityKeyData, str. separated by spaces every 8 bytes */
@property (nonatomic, strong, readonly) NSString *humanReadableFingerprint;

// First Time seing device list all trusted
// Any new devices after that are not trusted and require user input
@property (nonatomic, readwrite) OMEMOTrustLevel trustLevel;

@property (nonatomic, strong, readwrite) NSDate *lastSeenDate;

/** (OMEMOTrustLevelTrustedTofu || OMEMOTrustLevelTrustedUser) && !isExpired */
- (BOOL) isTrusted;

/** if lastSeenDate is > 30 days */
- (BOOL) isExpired;

/** if lastSeenDate is nil, it is set to NSDate.date */
- (instancetype) initWithDeviceId:(NSNumber *)deviceId
                                trustLevel:(OMEMOTrustLevel)trustLevel
                                 parentKey:(NSString *)parentKey
                          parentCollection:(NSString *)parentCollection
                     publicIdentityKeyData:(nullable NSData *)publicIdentityKeyData
                            lastSeenDate:(nullable NSDate *)lastSeenDate;


+ (void)enumerateDevicesForParentKey:(NSString *)key
                          collection:(NSString *)collection
                         transaction:(YapDatabaseReadTransaction *)transaction
                          usingBlock:(void (^)(OTROMEMODevice * _Nonnull device, BOOL * _Nonnull stop))block;

+ (NSArray <OTROMEMODevice *>*)allDevicesForParentKey:(NSString *)key
                                           collection:(NSString *)collection
                                          transaction:(YapDatabaseReadTransaction *)transaction;

+ (NSArray <OTROMEMODevice *>*)allDevicesForParentKey:(NSString *)key
                                           collection:(NSString *)collection
                                              trusted:(BOOL)trusted
                                          transaction:(YapDatabaseReadTransaction *)transaction;

+ (NSString *)yapKeyWithDeviceId:(NSNumber *)deviceId
                       parentKey:(NSString *)parentKey
                parentCollection:(NSString *)parentCollection;

@end

NS_ASSUME_NONNULL_END
