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
@import OTRAssets;
#import "OTRLanguageManager.h"
#import "XMPPJID.h"
#import "XMPPStream.h"
#import "XMPPvCardTemp.h"
#import "NSData+XMPP.h"

static NSUInteger const OTRDefaultPortNumber = 5222;

@implementation OTRXMPPAccount
@synthesize vCardTemp = _vCardTemp;
@synthesize lastUpdatedvCardTemp = _lastUpdatedvCardTemp;
@synthesize waitingForvCardTempFetch = _waitingForvCardTempFetch;
@synthesize photoHash = _photoHash;

- (id)init
{
    if (self = [super init]) {
        self.port = [OTRXMPPAccount defaultPort];
        self.resource = [OTRXMPPAccount newResource];
        self.autologin = YES;
        self.rememberPassword = YES;
    }
    return self;
}

- (OTRProtocolType)protocolType
{
    return OTRProtocolTypeXMPP;
}

- (NSString *)protocolTypeString
{
    return kOTRProtocolTypeXMPP;
}

- (UIImage *)accountImage
{
    return [UIImage imageNamed:OTRXMPPImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
}
- (NSString *)accountDisplayName
{
    return JABBER_STRING;
}

- (Class)protocolClass {
    return [OTRXMPPManager class];
}

#pragma - mark Class Methods

+ (NSString *)collection
{
    return NSStringFromClass([OTRAccount class]);
}

+ (int)defaultPort
{
    return OTRDefaultPortNumber;
}

+ (instancetype)accountForStream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    id xmppAccount = nil;
    if([stream.tag isKindOfClass:[NSString class]]) {
        
        xmppAccount = [self fetchObjectWithUniqueID:stream.tag transaction:transaction];
    }
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


@end
