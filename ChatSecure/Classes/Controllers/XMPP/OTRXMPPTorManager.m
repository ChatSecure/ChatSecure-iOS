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
#import "OTRXMPPError.h"
#import "OTRProtocol.h"
#import "OTRXMPPManager_Private.h"


@interface OTRXMPPTorManager()
@property (nonatomic, strong) OTRXMPPTorAccount *account;
@end

@implementation OTRXMPPTorManager

- (void) connectUserInitiated:(BOOL)userInitiated {
    if ([OTRTorManager sharedInstance].torManager.isConnected) {
        [super connectUserInitiated:userInitiated];
    } else {
        NSError * error = [NSError errorWithDomain:OTRXMPPErrorDomain code:OTRXMPPTorError userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Need to connect to Tor first.", @"")}];
        [self failedToConnect:error];
    }
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
