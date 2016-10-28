//
//  OTROMEMODevice.m
//  ChatSecure
//
//  Created by David Chiles on 9/14/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTROMEMODevice.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

@implementation OTROMEMODevice

- (instancetype) initWithDeviceId:(NSNumber *)deviceId trustLevel:(OMEMOTrustLevel)trustLevel parentKey:(NSString *)parentKey parentCollection:(NSString *)parentCollection publicIdentityKeyData:(nullable NSData *)publicIdentityKeyData lastSeenDate:(nullable NSDate *)lastSeenDate
{
    if (self = [super init]) {
        _deviceId = deviceId;
        _parentKey = parentKey;
        _parentCollection = parentCollection;
        _trustLevel = trustLevel;
        _publicIdentityKeyData = publicIdentityKeyData;
        if (!_lastSeenDate) {
            _lastSeenDate = [NSDate date];
        }
    }
    return self;
}

- (NSString *)uniqueId {
    return [[self class] yapKeyWithDeviceId:self.deviceId parentKey:self.parentKey parentCollection:self.parentCollection];
}

/** (OMEMOTrustLevelTrustedTofu || OMEMOTrustLevelTrustedUser) && !isExpired */
- (BOOL) isTrusted {
    return (_trustLevel == OMEMOTrustLevelTrustedTofu || _trustLevel == OMEMOTrustLevelTrustedUser) && ![self isExpired];
}

/** if lastSeenDate is > 30 days */
- (BOOL) isExpired {
    if (!self.lastSeenDate) {
        return YES;
    }
    NSTimeInterval span = [[NSDate date] timeIntervalSinceDate:self.lastSeenDate];
    NSTimeInterval thirtyDays = 86400 * 30;
    if (span > thirtyDays) {
        return YES;
    }
    return NO;
}

- (NSString*) humanReadableFingerprint {
    if (!self.publicIdentityKeyData) {
        return @"";
    }
    NSData *fingerprintData = [NSData data];
    if (self.publicIdentityKeyData.length == 32) {
        fingerprintData = self.publicIdentityKeyData;
    } else if (self.publicIdentityKeyData.length >= 33) {
        // why is there an extra 0x05 at the front?
        // maybe blame libsignal-protocol-c library
        fingerprintData = [self.publicIdentityKeyData subdataWithRange:NSMakeRange(1, 32)];
    }
    NSString *fingerprint = [fingerprintData humanReadableFingerprint];
    return fingerprint;
}

+ (void)enumerateDevicesForParentKey:(NSString *)key collection:(NSString *)collection transaction:(YapDatabaseReadTransaction *)transaction usingBlock:(void (^)(OTROMEMODevice * _Nonnull device, BOOL * _Nonnull stop))block
{
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameOmemoDeviceEdgeName];
    
    [((YapDatabaseRelationshipTransaction *)[transaction ext:extensionName]) enumerateEdgesWithName:edgeName destinationKey:key collection:collection usingBlock:^(YapDatabaseRelationshipEdge * _Nonnull edge, BOOL * _Nonnull stop) {
        
        id possibleDevice = [transaction objectForKey:edge.sourceKey inCollection:edge.sourceCollection];
        if (possibleDevice != nil && [possibleDevice isKindOfClass:[OTROMEMODevice class] ]) {
            OTROMEMODevice *device = possibleDevice;
            block(device,stop);
        }
    }];
}

+ (NSArray <OTROMEMODevice *>*)allDevicesForParentKey:(NSString *)key collection:(NSString *)collection transaction:(YapDatabaseReadTransaction *)transaction {
    __block NSMutableArray <OTROMEMODevice *>*devices = [[NSMutableArray alloc] init];
    [self enumerateDevicesForParentKey:key collection:collection transaction:transaction usingBlock:^(OTROMEMODevice * _Nonnull device, BOOL * _Nonnull stop) {
        [devices addObject:device];
    }];
    return [devices copy];
}

+ (NSArray <OTROMEMODevice *>*)allDevicesForParentKey:(NSString *)key collection:(NSString *)collection trusted:(BOOL)trusted transaction:(YapDatabaseReadTransaction *)transaction {
    __block NSMutableArray <OTROMEMODevice *>*devices = [[NSMutableArray alloc] init];
    [self enumerateDevicesForParentKey:key collection:collection transaction:transaction usingBlock:^(OTROMEMODevice * _Nonnull device, BOOL * _Nonnull stop) {
        if (device.isTrusted == trusted) {
            [devices addObject:device];
        }
    }];
    return [devices copy];
}

#pragma MARK YapDatabaseRelationshipNode Methods

- (nullable NSArray<YapDatabaseRelationshipEdge *> *)yapDatabaseRelationshipEdges
{
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameOmemoDeviceEdgeName];
    YapDatabaseRelationshipEdge *edge = [YapDatabaseRelationshipEdge edgeWithName:edgeName destinationKey:self.parentKey collection:self.parentCollection nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
    if (edge) {
        return @[edge];
    }
    return nil;
}

#pragma MARK Class Methods

+ (NSString *)yapKeyWithDeviceId:(NSNumber *)deviceId parentKey:(NSString *)parentKey parentCollection:(NSString *)parentCollection
{
    return [NSString stringWithFormat:@"%@-%@-%@",deviceId,parentKey,parentCollection];
}

@end
