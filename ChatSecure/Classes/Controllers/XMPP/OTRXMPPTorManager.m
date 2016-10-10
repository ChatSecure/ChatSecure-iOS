//
//  OTRXMPPTorManager.m
//  Off the Record
//
//  Created by David Chiles on 1/17/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPTorManager.h"
#import "OTRTorManager.h"
@import XMPPFramework;
#import "OTRXMPPTorAccount.h"

@interface OTRXMPPTorManager()
@property (nonatomic, strong) OTRXMPPTorAccount *account;
@end

@implementation OTRXMPPTorManager
@synthesize account = _account;
@synthesize xmppStream = _xmppStream;

- (void)connectWithPassword:(NSString *)password userInitiated:(BOOL)userInitiated
{
    if ([OTRTorManager sharedInstance].torManager.isConnected) {
        [super connectWithPassword:password userInitiated:userInitiated];
    }
    else {
        NSError * error = [NSError errorWithDomain:OTRXMPPErrorDomain code:OTRXMPPTorError userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Need to connect to Tor first.", @"")}];
        [self failedToConnect:error];
    }
}

- (void)connectWithPassword:(NSString *)password
{
    [self connectWithPassword:password userInitiated:NO];
}

-(XMPPStream *)xmppStream
{
    if (!_xmppStream) {
        _xmppStream = [super xmppStream];
        NSString *proxyHost = [OTRTorManager sharedInstance].torManager.SOCKSHost;
        NSUInteger proxyPort = [OTRTorManager sharedInstance].torManager.SOCKSPort;
        [_xmppStream setProxyHost:proxyHost port:proxyPort version:GCDAsyncSocketSOCKSVersion5];
        [_xmppStream setProxyUsername:[[NSUUID UUID] UUIDString] password:[[NSUUID UUID] UUIDString]];
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
