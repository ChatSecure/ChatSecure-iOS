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

// First Time seing device list all trusted
// Any new devices after that are not trusted and require user input
@property (nonatomic, readonly) OMEMODeviceTrustLevel trustLevel;

- (nullable instancetype) initWithDeviceId:(NSNumber *)deviceId trustLevel:(OMEMODeviceTrustLevel)trustLevel parentKey:(NSString *)parentKey parentCollection:(NSString *)parentCollection;


+ (NSArray <OTROMEMODevice *>*)allDeviceIdsForParentKey:(NSString *)key
                                             collection:(NSString *)collection
                                            transaction:(YapDatabaseReadTransaction *)transaction;

+ (NSString *)yapKeyWithDeviceId:(NSNumber *)deviceId
                       parentKey:(NSString *)parentKey
                parentCollection:(NSString *)parentCollection;

@end

NS_ASSUME_NONNULL_END