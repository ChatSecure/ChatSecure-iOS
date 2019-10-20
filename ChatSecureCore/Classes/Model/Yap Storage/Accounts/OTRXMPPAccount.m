//
//  OTRXMPPAccount.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPAccount.h"
#import "OTRXMPPManager.h"
#import "OTRConstants.h"
#import "ChatSecureCoreCompat-Swift.h"
@import OTRAssets;

@import XMPPFramework;

static NSUInteger const OTRDefaultPortNumber = 5222;

@implementation OTRXMPPAccount
@synthesize vCardTemp = _vCardTemp;
@synthesize lastUpdatedvCardTemp = _lastUpdatedvCardTemp;
@dynamic waitingForvCardTempFetch;
@synthesize photoHash = _photoHash;

- (instancetype) initWithUsername:(NSString *)username accountType:(OTRAccountType)accountType {
    if (self = [super initWithUsername:username accountType:accountType]) {
        _port = [[self class] defaultPort];
        _resource = [[self class] newResource];
        self.autologin = YES;
        self.rememberPassword = YES;
    }
    return self;
}

- (UIImage *)accountImage
{
    return [UIImage imageNamed:OTRXMPPImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
}

- (Class)protocolClass {
    return [OTRXMPPManager class];
}

#pragma - mark Class Methods

+ (NSString *)collection
{
    return NSStringFromClass([OTRAccount class]);
}

+ (uint16_t)defaultPort
{
    return OTRDefaultPortNumber;
}

+ (instancetype)accountForStream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    NSParameterAssert(stream);
    NSParameterAssert(transaction);
    if (!stream || !transaction) { return nil; }
    if (![stream.tag isKindOfClass:[NSString class]]) {
        return nil;
    }
    OTRXMPPAccount *xmppAccount = [self fetchObjectWithUniqueID:stream.tag transaction:transaction];
    return xmppAccount;
}

+ (NSString * )newResource
{
    int r = arc4random() % 99999;
    return [NSString stringWithFormat:@"%@%d",[OTRBranding xmppResource],r];
}

- (void)setVCardTemp:(XMPPvCardTemp *)vCardTemp
{
    _vCardTemp = vCardTemp;
    if ([self.vCardTemp.photo length]) {
        self.avatarData = self.vCardTemp.photo;
    }
    if (self.vCardTemp.nickname.length) {
        self.displayName = self.vCardTemp.nickname;
    } else if (self.vCardTemp.formattedName.length) {
        self.displayName = self.vCardTemp.formattedName;
    }
}

// If forwarding JID is set, assume account is archived
- (BOOL) isArchived {
    if (!self.vCardTemp.jid) {
        return NO;
    } else if (![self.vCardTemp.jid isEqualToJID:self.bareJID options:XMPPJIDCompareBare]) {
        return YES;
    }
    return NO;
}

- (void)setAvatarData:(NSData *)avatarData
{
    [super setAvatarData:avatarData];
    if ([self.avatarData length]) {
        self.photoHash = [[self.avatarData xmpp_sha1Digest] xmpp_hexStringValue];
    }
    else {
        self.photoHash = nil;
    }
}

- (nullable XMPPJID*) bareJID {
    return [XMPPJID jidWithString:self.username];
}

- (NSArray *)allRoomsWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSMutableArray *allRooms = [NSMutableArray array];
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameRoom];
    [[transaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:self.uniqueId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRXMPPRoom *room = [OTRXMPPRoom fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (room) {
            [allRooms addObject:room];
        }
    }];
    return allRooms;
}

- (BOOL) waitingForvCardTempFetch {
    return [OTRBuddyCache.shared waitingForvCardTempFetchForVcard:self];
}

- (void) setWaitingForvCardTempFetch:(BOOL)waitingForvCardTempFetch {
    [OTRBuddyCache.shared setWaitingForvCardTempFetch:waitingForvCardTempFetch forVcard:self];
}

#pragma - mark Class Methods

#pragma mark Disable Mantle Storage of Dynamic Properties

+ (NSSet<NSString*>*) excludedProperties {
    static NSSet<NSString*>* excludedProperties = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        excludedProperties = [NSSet setWithArray:@[NSStringFromSelector(@selector(waitingForvCardTempFetch))]];
    });
    return excludedProperties;
}

// See MTLModel+NSCoding.h
// This helps enforce that only the properties keys that we
// desire will be encoded. Be careful to ensure that values
// that should be stored in the keychain don't accidentally
// get serialized!
+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    NSMutableDictionary *behaviors = [NSMutableDictionary dictionaryWithDictionary:[super encodingBehaviorsByPropertyKey]];
    NSSet<NSString*> *excludedProperties = [self excludedProperties];
    [excludedProperties enumerateObjectsUsingBlock:^(NSString * _Nonnull selector, BOOL * _Nonnull stop) {
        [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:selector];
    }];
    return behaviors;
}

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
    NSSet<NSString*> *excludedProperties = [self excludedProperties];
    if ([excludedProperties containsObject:propertyKey]) {
        return MTLPropertyStorageNone;
    }
    return [super storageBehaviorForPropertyWithKey:propertyKey];
}



@end
