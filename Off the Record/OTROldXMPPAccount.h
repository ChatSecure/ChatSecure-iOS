//
//  OTRXMPPAccount.h
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

#import "OTROldAccount.h"

#define kOTRAccountDomainKey @"domain"

@interface OTRXMPPAccount : OTRAccount

@property (nonatomic) BOOL allowSelfSignedSSL;
@property (nonatomic) BOOL allowSSLHostNameMismatch;
@property (nonatomic) BOOL sendDeliveryReceipts;
@property (nonatomic) BOOL sendTypingNotifications;
@property (nonatomic) BOOL allowPlainTextAuthentication;
@property (nonatomic) BOOL requireTLS;
@property (nonatomic, retain) NSString *domain; // xmpp only, used for custom domains
@property (nonatomic) UInt16 port;

- (id) initWithDomain:(NSString*)newDomain;

+(UInt16)defaultPortNumber;

@end
