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
#import "OTRXMPPError.h"


@interface OTRXMPPManager(Private)
// private internal methods for override
- (void)setupStream;
@end

@interface OTRXMPPTorManager()
@end

@implementation OTRXMPPTorManager

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

// override
- (void) setupStream {
    [super setupStream];
    NSString *proxyHost = [OTRTorManager sharedInstance].torManager.SOCKSHost;
    NSUInteger proxyPort = [OTRTorManager sharedInstance].torManager.SOCKSPort;
    [self.xmppStream setProxyHost:proxyHost port:proxyPort version:GCDAsyncSocketSOCKSVersion5];
    [self.xmppStream setProxyUsername:[[NSUUID UUID] UUIDString] password:[[NSUUID UUID] UUIDString]];
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
