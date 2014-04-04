//
//  OTRXMPPBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPBuddy.h"
#import "XMPPvCardTemp.h"
#import "NSData+XMPP.h"

const struct OTRXMPPBuddyAttributes OTRXMPPBuddyAttributes = {
	.pendingApproval = @"pendingApproval",
    .vCardTemp = @"vCardTemp",
    .photoHash = @"photoHash",
    .waitingForvCardTempFetch = @"waitingForvCardTempFetch",
    .lastUpdatedvCardTemp = @"lastUpdatedvCardTemp"
};


@implementation OTRXMPPBuddy

- (id)init
{
    if (self = [super init]) {
        self.pendingApproval = NO;
        self.waitingForvCardTempFetch = NO;
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


#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder *)decoder // NSCoding deserialization
{
    if (self = [super initWithCoder:decoder]) {
        self.pendingApproval = [decoder decodeBoolForKey:OTRXMPPBuddyAttributes.pendingApproval];
        self.photoHash = [decoder decodeObjectForKey:OTRXMPPBuddyAttributes.photoHash];
        self.vCardTemp = [decoder decodeObjectForKey:OTRXMPPBuddyAttributes.vCardTemp];
        self.waitingForvCardTempFetch = [decoder decodeBoolForKey:OTRXMPPBuddyAttributes.waitingForvCardTempFetch];
        self.lastUpdatedvCardTemp = [decoder decodeObjectForKey:OTRXMPPBuddyAttributes.lastUpdatedvCardTemp];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder // NSCoding serialization
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeBool:self.isPendingApproval forKey:OTRXMPPBuddyAttributes.pendingApproval];
    [encoder encodeObject:self.photoHash forKey:OTRXMPPBuddyAttributes.photoHash];
    [encoder encodeObject:self.vCardTemp forKey:OTRXMPPBuddyAttributes.vCardTemp];
    [encoder encodeBool:self.waitingForvCardTempFetch forKey:OTRXMPPBuddyAttributes.waitingForvCardTempFetch];
    [encoder encodeObject:self.lastUpdatedvCardTemp forKey:OTRXMPPBuddyAttributes.lastUpdatedvCardTemp];
}

#pragma - mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OTRXMPPBuddy *copy = [super copyWithZone:zone];
    copy.pendingApproval = self.pendingApproval;
    copy.vCardTemp = [self.vCardTemp copyWithZone:zone];
    copy.photoHash = [self.photoHash copyWithZone:zone];
    copy.lastUpdatedvCardTemp = [self.lastUpdatedvCardTemp copyWithZone:zone];
    copy.waitingForvCardTempFetch = self.waitingForvCardTempFetch;
    
    return copy;
}

#pragma - mark Class Methods

+ (NSString *)collection
{
    return [OTRBuddy collection];
}



@end
