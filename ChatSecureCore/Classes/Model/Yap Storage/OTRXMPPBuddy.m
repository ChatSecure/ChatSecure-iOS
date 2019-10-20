//
//  OTRXMPPBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPBuddy.h"
#import "OTRBuddyCache.h"
#import "ChatSecureCoreCompat-Swift.h"
@import XMPPFramework;
@import OTRAssets;

NSString *const OTRBuddyPendingApprovalDidChangeNotification = @"OTRBuddyPendingApprovalDidChangeNotification";

@implementation OTRXMPPBuddy
@synthesize vCardTemp = _vCardTemp;
@synthesize lastUpdatedvCardTemp = _lastUpdatedvCardTemp;
@synthesize photoHash = _photoHash;
@dynamic waitingForvCardTempFetch;

- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion {
    if (modelVersion == 0) {
        // Migrate from version 0 of model, where we had "hasIncomingSubscriptionRequest" and "pendingApproval" flags.
        if ([key isEqualToString:@"subscription"]) {
            SubscriptionAttribute subscription = SubscriptionAttributeNone;
            return [NSNumber numberWithInt:(int)subscription];
        } else if ([key isEqualToString:@"pending"]) {
            SubscriptionPendingAttribute pending = SubscriptionPendingAttributePendingNone;
            BOOL hasIncomingSubscriptionRequest = [[coder decodeObjectForKey:@"hasIncomingSubscriptionRequest"] boolValue];
            BOOL pendingApproval = [[coder decodeObjectForKey:@"pendingApproval"] boolValue];
            if (hasIncomingSubscriptionRequest) {
                pending = [SubscriptionPendingAttributeBridge setPendingIn:pending pending:YES];
            }
            pending = [SubscriptionPendingAttributeBridge setPendingOut:pending pending:pendingApproval];
            return [NSNumber numberWithInt:(int)pending];
        } else if ([key isEqualToString:@"trustLevel"]) {
            BuddyTrustLevel trustLevel = BuddyTrustLevelUntrusted;
            
            BOOL hasIncomingSubscriptionRequest = [[coder decodeObjectForKey:@"hasIncomingSubscriptionRequest"] boolValue];
            if (hasIncomingSubscriptionRequest == NO) {
                trustLevel = BuddyTrustLevelRoster;
            }
            return [NSNumber numberWithInt:(int)trustLevel];
        }
    }
    return [super decodeValueForKey:key withCoder:coder modelVersion:modelVersion];
}

- (id)init
{
    if (self = [super init]) {
        self.trustLevel = BuddyTrustLevelUntrusted;
    }
    return self;
}

- (instancetype) initWithJID:(XMPPJID *)jid
                   accountId:(NSString*)accountId {
    if (self = [self init]) {
        self.username = [jid.bare copy];
        self.accountUniqueId = [accountId copy];
    }
    return self;
}

#pragma - mark setters & getters

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

- (void) setWaitingForvCardTempFetch:(BOOL)waitingForvCardTempFetch {
    [OTRBuddyCache.shared setWaitingForvCardTempFetch:waitingForvCardTempFetch forVcard:self];
}

- (BOOL) waitingForvCardTempFetch {
    return [OTRBuddyCache.shared waitingForvCardTempFetchForVcard:self];
}

- (NSString *)threadName
{
    NSString *threadName = [super threadName];
    if (self.pendingApproval) {
        threadName = [NSString stringWithFormat:@"%@ - %@", threadName, PENDING_APPROVAL_STRING()];
    }
    return threadName;
}

- (nullable XMPPJID*) bareJID {
    return [XMPPJID jidWithString:self.username];
}

#pragma - mark Class Methods

+ (NSUInteger)modelVersion {
    return 1;
}

+ (NSString *)collection
{
    return [OTRBuddy collection];
}

#pragma mark Disable Mantle Storage of Dynamic Properties

+ (NSSet<NSString*>*) excludedProperties {
    static NSSet<NSString*>* excludedProperties = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        excludedProperties = [[super excludedProperties] setByAddingObject:NSStringFromSelector(@selector(waitingForvCardTempFetch))];
    });
    return excludedProperties;
}

@end
