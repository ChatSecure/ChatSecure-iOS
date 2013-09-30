//
//  OTRManagedXMPPAccount.m
//  Off the Record
//
//  Created by Christopher Ballinger on 1/10/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
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

#import "OTRManagedXMPPAccount.h"
#import "OTRProtocol.h"
#import "OTRConstants.h"
#import "Strings.h"
#import "OTRXMPPManager.h"

#define DEFAULT_PORT_NUMBER 5222

@interface OTRManagedXMPPAccount()
@end


@implementation OTRManagedXMPPAccount

- (void) setDefaultsWithDomain:(NSString *)newDomain {
    [super setDefaultsWithProtocol:kOTRProtocolTypeXMPP];
    self.domain = newDomain;
    [self setAllowSelfSignedSSLValue: NO];
    [self setAllowSSLHostNameMismatchValue: NO];
    self.port = @(DEFAULT_PORT_NUMBER); // Default XMPP port number
    [self setSendDeliveryReceiptsValue: NO];
    [self setSendTypingNotificationsValue: YES]; // Default typing notifications to yes
    [self setAllowPlainTextAuthenticationValue:NO];
    [self setRequireTLSValue:NO];
}

+(NSNumber *)defaultPortNumber {
    return @(DEFAULT_PORT_NUMBER);
}

- (NSString *) imageName {
    return kXMPPImageName;
}

-(NSString *)providerName
{
    return JABBER_STRING;
}

// Don't allow self-signed SSL for Facebook and Google Talk
- (BOOL) shouldAllowSelfSignedSSL {
    return self.allowSelfSignedSSLValue;
}

- (void) setShouldAllowSelfSignedSSL:(BOOL)shouldAllowSelfSignedSSL {
    self.allowSelfSignedSSL = @(shouldAllowSelfSignedSSL);
}

- (BOOL) shouldAllowSSLHostNameMismatch {
    
    return self.allowSSLHostNameMismatchValue;
}

- (void) setShouldAllowSSLHostNameMismatch:(BOOL)shouldAllowSSLHostNameMismatch {
    self.allowSSLHostNameMismatchValue = @(shouldAllowSSLHostNameMismatch);
}

- (BOOL) shouldAllowPlainTextAuthentication
{
    return self.allowPlainTextAuthenticationValue;
}
- (BOOL) shouldRequireTLS
{
    return self.requireTLSValue;
}

-(OTRAccountType)accountType
{
    return OTRAccountTypeJabber;
}

- (Class)protocolClass {
    return [OTRXMPPManager class];
}

@end
