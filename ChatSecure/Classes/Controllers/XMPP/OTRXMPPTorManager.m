//
//  OTRXMPPTorManager.m
//  Off the Record
//
//  Created by David Chiles on 1/17/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPTorManager.h"
#import "OTRTorManager.h"
#import "XMPPStream.h"
#import "OTRXMPPTorAccount.h"

@interface OTRXMPPTorManager()
@property (nonatomic, strong) OTRXMPPTorAccount *account;
@end

@implementation OTRXMPPTorManager

@synthesize xmppStream = _xmppStream;

- (void)connectWithPassword:(NSString *)myPassword
{
    if ([OTRTorManager sharedInstance].torManager.isConnected) {
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
        NSString *proxyHost = [OTRTorManager sharedInstance].torManager.SOCKSHost;
        NSUInteger proxyPort = [OTRTorManager sharedInstance].torManager.SOCKSPort;
        [_xmppStream setProxyHost:proxyHost port:proxyPort version:GCDAsyncSocketSOCKSVersion5];
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
