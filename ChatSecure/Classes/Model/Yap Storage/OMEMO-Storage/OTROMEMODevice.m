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

- (nullable instancetype) initWithDeviceId:(NSNumber *)deviceId trustLevel:(OMEMODeviceTrustLevel)trustLevel parentKey:(NSString *)parentKey parentCollection:(NSString *)parentCollection publicIdentityKeyData:(nullable NSData *)publicIdentityKeyData
{
    if (self = [super init]) {
        _deviceId = deviceId;
        _parentKey = parentKey;
        _parentCollection = parentCollection;
        _trustLevel = trustLevel;
        publicIdentityKeyData = publicIdentityKeyData;
    }
    return self;
}

- (NSString *)uniqueId {
    return [[self class] yapKeyWithDeviceId:self.deviceId parentKey:self.parentKey parentCollection:self.parentCollection];
}

/** OMEMOTrustLevelTrustedTofu || OMEMOTrustLevelTrustedUser */
- (BOOL) isTrusted {
    return _trustLevel == OMEMOTrustLevelTrustedTofu || _trustLevel == OMEMOTrustLevelTrustedUser;
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
    return devices;
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
