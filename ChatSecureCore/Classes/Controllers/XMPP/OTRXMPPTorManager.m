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
@import CPAProxy;
#import "OTRXMPPTorAccount.h"
#import "OTRXMPPError.h"
#import "OTRProtocol.h"
#import "OTRXMPPManager_Private.h"
#import "ProxyXMPPStream.h"

@interface OTRXMPPTorManager()
@end

@implementation OTRXMPPTorManager

- (void) connectUserInitiated:(BOOL)userInitiated {
    if ([OTRTorManager sharedInstance].torManager.isConnected) {
        [super connectUserInitiated:userInitiated];
    } else {
        NSError * error = [NSError errorWithDomain:OTRXMPPErrorDomain code:OTRXMPPErrorCodeTorError userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Need to connect to Tor first.", @"")}];
        [self failedToConnect:error];
    }
}

/** Override XMPPStream with XMPPProxyStream */
- (XMPPStream*) newStream {
    return [[ProxyXMPPStream alloc] init];
}

// override
- (void) setupStream {
    [super setupStream];
    NSString *proxyHost = [OTRTorManager sharedInstance].torManager.SOCKSHost;
    NSUInteger proxyPort = [OTRTorManager sharedInstance].torManager.SOCKSPort;
    if ([self.xmppStream isKindOfClass:[ProxyXMPPStream class]]) {
        ProxyXMPPStream *proxyStream = (ProxyXMPPStream*)self.xmppStream;
        [proxyStream setProxyHost:proxyHost port:proxyPort version:GCDAsyncSocketSOCKSVersion5];
        [proxyStream setProxyUsername:[[NSUUID UUID] UUIDString] password:[[NSUUID UUID] UUIDString]];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Stream socket is of wrong class!" userInfo:nil];
    }
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
    
    if (!domainString.length && error) {
        *error = [NSError errorWithDomain:OTRXMPPErrorDomain code:OTRXMPPErrorCodeDomainError userInfo:@{NSLocalizedDescriptionKey:@"Tor accounts require a valid domain"}];
    }
    
    return domainString;
}

@end
