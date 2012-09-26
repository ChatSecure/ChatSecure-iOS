//
//  OTRXMPPAccount.m
//  Off the Record
//
//  Created by Christopher Ballinger on 8/9/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRXMPPAccount.h"
#import "OTRProtocol.h"
#import "OTRConstants.h"
#import "Strings.h"
#import "OTRXMPPManager.h"

#define DEFAULT_PORT_NUMBER 5222

@implementation OTRXMPPAccount
@synthesize allowSelfSignedSSL, allowSSLHostNameMismatch, domain, port;

- (id) initWithDomain:(NSString *)newDomain {
    if (self = [super initWithProtocol:kOTRProtocolTypeXMPP]) {
        self.domain = newDomain;
        self.allowSelfSignedSSL = NO;
        self.allowSSLHostNameMismatch = NO;
        self.port = DEFAULT_PORT_NUMBER; // Default XMPP port number
    }
    return self;
}

- (id) initWithSettingsDictionary:(NSDictionary *)dictionary uniqueIdentifier:(NSString*) uniqueID {
    if (self = [super initWithSettingsDictionary:dictionary uniqueIdentifier:uniqueID]) {
        self.domain = [dictionary objectForKey:kOTRAccountDomainKey];
        self.allowSelfSignedSSL = [[dictionary objectForKey:kOTRXMPPAccountAllowSelfSignedSSLKey] boolValue];
        self.allowSSLHostNameMismatch = [[dictionary objectForKey:kOTRXMPPAccountAllowSSLHostNameMismatch] boolValue];
        NSNumber *portNumber = [dictionary objectForKey:kOTRXMPPAccountPortNumber];
        if (portNumber) {
            self.port = [portNumber intValue];
        } else {
            self.port = DEFAULT_PORT_NUMBER;
        }
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

// Don't allow self-signed SSL for Facebook and Google Talk
- (BOOL) allowSelfSignedSSL {
    if ([domain isEqualToString:kOTRFacebookDomain] || [domain isEqualToString:kOTRGoogleTalkDomain]) {
        return NO;
    }
    return allowSelfSignedSSL;
}

// Don't allow SSL host-name mismatch for Facebook or Google Talk
- (BOOL) allowSSLHostNameMismatch {
    if ([domain isEqualToString:kOTRFacebookDomain] || [domain isEqualToString:kOTRGoogleTalkDomain]) {
        return NO;
    }
    return allowSSLHostNameMismatch;
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
    [accountDictionary setObject:[NSNumber numberWithBool:self.allowSelfSignedSSL] forKey:kOTRXMPPAccountAllowSelfSignedSSLKey];
    [accountDictionary setObject:[NSNumber numberWithBool:self.allowSSLHostNameMismatch] forKey:kOTRXMPPAccountAllowSSLHostNameMismatch];
    [accountDictionary setObject:[NSNumber numberWithInt:self.port] forKey:kOTRXMPPAccountPortNumber];
    return accountDictionary;
}

+(UInt16)defaultPortNumber {
    return DEFAULT_PORT_NUMBER;
}

@end
