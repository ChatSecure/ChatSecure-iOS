//
//  OTRXMPPAccount.m
//  Off the Record
//
//  Created by Christopher Ballinger on 8/9/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPAccount.h"
#import "OTRProtocol.h"
#import "OTRConstants.h"
#import "Strings.h"
#import "OTRXMPPManager.h"

@implementation OTRXMPPAccount
@synthesize allowSelfSignedSSL, allowSSLHostNameMismatch, domain;

- (id) initWithDomain:(NSString *)newDomain {
    if (self = [super initWithProtocol:kOTRProtocolTypeXMPP]) {
        self.domain = newDomain;
        self.allowSelfSignedSSL = NO;
        self.allowSSLHostNameMismatch = NO;
    }
    return self;
}

- (id) initWithSettingsDictionary:(NSDictionary *)dictionary uniqueIdentifier:(NSString*) uniqueID {
    if (self = [super initWithSettingsDictionary:dictionary uniqueIdentifier:uniqueID]) {
        self.domain = [dictionary objectForKey:kOTRAccountDomainKey];
    }
    return self;
}

- (NSString *) imageName {
    NSString *imageName = kXMPPImageName;
    if([domain isEqualToString:kOTRFacebookDomain])
    {
        imageName = kFacebookImageName;
    }
    else if ([domain isEqualToString:kOTRGoogleTalkDomain] )
    {
        imageName = kGTalkImageName;
    }
    return imageName;
}

- (NSString *)providerName {
    if ([domain isEqualToString:kOTRFacebookDomain]) {
        return FACEBOOK_STRING;
    }
    else if ([domain isEqualToString:kOTRGoogleTalkDomain])
    {
        return GOOGLE_TALK_STRING;
    }
    else {
        return JABBER_STRING;
    }
}

- (Class)protocolClass {
    return [OTRXMPPManager class];
}

- (NSDictionary*) accountDictionary {
    NSMutableDictionary *accountDictionary = [super accountDictionary];
    [accountDictionary setObject:self.domain forKey:kOTRAccountDomainKey];
    return accountDictionary;
}
@end
