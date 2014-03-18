//
//  OTRXMPPTorManager.m
//  Off the Record
//
//  Created by David Chiles on 1/17/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPTorManager.h"
#import "HITorManager.h"
#import "XMPPStream.h"

NSString *const proxyAdress = @"127.0.0.1";
uint16_t const proxyPort = 9050;

@interface OTRXMPPTorManager()
@property (nonatomic, strong) OTRManagedXMPPAccount * account;
@end

@implementation OTRXMPPTorManager

@synthesize xmppStream = _xmppStream;

- (void)connectWithPassword:(NSString *)myPassword
{
    if ([HITorManager defaultManager].isRunning) {
        [super connectWithPassword:myPassword];
    }
    else {
        NSError * error = [NSError errorWithDomain:OTRXMPPErrorDomain code:OTRXMPPTorError userInfo:@{NSLocalizedDescriptionKey:@"Need to connect to Tor"}];
        [self failedToConnect:error];
    }
}

-(XMPPStream *)xmppStream
{
    if (!_xmppStream) {
        _xmppStream = [super xmppStream];
        [_xmppStream setProxyHost:proxyAdress port:proxyPort version:GCDAsyncSocketSOCKSVersion5];
    }
    return _xmppStream;
}

- (NSString *)accountDomainWithError:(NSError**)error;
{
    NSString * domainString = nil;
    if (self.account.domain.length) {
        domainString = self.account.domain;
    }
    else {
        XMPPJID * jid = [XMPPJID jidWithString:self.account.username];
        domainString = jid.domain;
    }
    
    if (!domainString.length) {
        *error = [NSError errorWithDomain:OTRXMPPErrorDomain code:OTRXMPPDomainError userInfo:@{NSLocalizedDescriptionKey:@"Tor accounts require a valid domain"}];
    }
    
    return domainString;
}

@end
