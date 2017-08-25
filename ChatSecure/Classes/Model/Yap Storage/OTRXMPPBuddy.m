//
//  OTRXMPPBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPBuddy.h"
#import "OTRBuddyCache.h"
@import XMPPFramework;
@import OTRAssets;

NSString *const OTRBuddyPendingApprovalDidChangeNotification = @"OTRBuddyPendingApprovalDidChangeNotification";

@implementation OTRXMPPBuddy
@synthesize vCardTemp = _vCardTemp;
@synthesize lastUpdatedvCardTemp = _lastUpdatedvCardTemp;
@synthesize photoHash = _photoHash;
@dynamic waitingForvCardTempFetch;

- (id)init
{
    if (self = [super init]) {
        self.pendingApproval = NO;
        self.hasIncomingSubscriptionRequest = NO;
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
    [OTRBuddyCache.shared setWaitingForvCardTempFetch:waitingForvCardTempFetch forBuddy:self];
}

- (BOOL) waitingForvCardTempFetch {
    return [OTRBuddyCache.shared waitingForvCardTempFetchForBuddy:self];
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
