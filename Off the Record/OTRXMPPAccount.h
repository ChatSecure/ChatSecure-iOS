//
//  OTRXMPPAccount.h
//  Off the Record
//
//  Created by Christopher Ballinger on 8/9/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRAccount.h"

#define kOTRAccountDomainKey @"domain"

@interface OTRXMPPAccount : OTRAccount

@property (nonatomic) BOOL allowSelfSignedSSL;
@property (nonatomic) BOOL allowSSLHostNameMismatch;
@property (nonatomic, retain) NSString *domain; // xmpp only, used for custom domains

- (id) initWithDomain:(NSString*)newDomain;

@end
