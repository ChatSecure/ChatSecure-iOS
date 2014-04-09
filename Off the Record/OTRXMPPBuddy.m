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

#pragma - mark Class Methods

+ (NSString *)collection
{
    return [OTRBuddy collection];
}



@end
