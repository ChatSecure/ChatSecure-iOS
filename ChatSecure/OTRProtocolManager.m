//
//  OTRProtocolManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
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

#import "OTRProtocolManager.h"
#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRMessage.h"
#import "OTRConstants.h"
#import "OTROAuthRefresher.h"
#import "OTROAuthXMPPAccount.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseConnection.h"
#import "YapDatabaseTransaction.h"
#import "OTRPushManager.h"
#import "OTRPushAPIClient.h"

#import "OTRLog.h"

static OTRProtocolManager *sharedManager = nil;

@interface OTRProtocolManager ()

@property (nonatomic) NSUInteger numberOfConnectedProtocols;
@property (nonatomic) NSUInteger numberOfConnectingProtocols;
@property (nonatomic, strong) OTRPushManager *pushManager;
@property (nonatomic, strong) NSMutableDictionary * protocolManagerDictionary;

@property (nonatomic) dispatch_queue_t internalQueue;

@end

@implementation OTRProtocolManager

-(id)init
{
    self = [super init];
    if(self)
    {
        self.numberOfConnectedProtocols = 0;
        self.numberOfConnectingProtocols = 0;
        self.encryptionManager = [[OTREncryptionManager alloc] init];
        self.protocolManagerDictionary = [NSMutableDictionary new];
    }
    return self;
}

- (void)removeProtocolForAccount:(OTRAccount *)account
{
    @synchronized(self.protocolManagerDictionary) {
        id protocol = self.protocolManagerDictionary[account.uniqueId];
        if (protocol) {
            [protocol removeObserver:self forKeyPath:NSStringFromSelector(@selector(connectionStatus))];
        }
        [self.protocolManagerDictionary removeObjectForKey:account.uniqueId];
    }
}

- (void)addProtocol:(id)protocol forAccount:(OTRAccount *)account
{
    @synchronized(self.protocolManagerDictionary){
        [self.protocolManagerDictionary setObject:protocol forKey:account.uniqueId];
        [protocol addObserver:self forKeyPath:NSStringFromSelector(@selector(connectionStatus)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
}

- (BOOL)existsProtocolForAccount:(OTRAccount *)account
{
    if ([account.uniqueId length]) {
        @synchronized(self.protocolManagerDictionary) {
            if ([self.protocolManagerDictionary objectForKey:account.uniqueId]) {
                return YES;
            }
        }
    }
    
    return NO;
}

#pragma mark -
#pragma mark Singleton Object Methods

+ (OTRProtocolManager*)sharedInstance {
    @synchronized(self) {
        if (sharedManager == nil) {
            sharedManager = [[self alloc] init];
        }
    }
    return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedManager == nil) {
            sharedManager = [super allocWithZone:zone];
            return sharedManager;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id <OTRProtocol>)protocolForAccount:(OTRAccount *)account
{
    NSObject <OTRProtocol> * protocol = [self.protocolManagerDictionary objectForKey:account.uniqueId];
    if(!protocol)
    {
        protocol = [[[account protocolClass] alloc] initWithAccount:account];
        if (protocol && account.uniqueId) {
            [self addProtocol:protocol forAccount:account];
        }
    }
    return protocol;
}

- (void)loginAccount:(OTRAccount *)account
{
    id <OTRProtocol> protocol = [self protocolForAccount:account];
    
    if([account isKindOfClass:[OTROAuthXMPPAccount class]])
    {
        [OTROAuthRefresher refreshAccount:(OTROAuthXMPPAccount *)account completion:^(id token, NSError *error) {
            if (!error) {
                ((OTROAuthXMPPAccount *)account).accountSpecificToken = token;
                [protocol connectWithPassword:account.password];
            }
            else {
                DDLogError(@"Error Refreshing Token");
            }
        }];
    }
    else
    {
        [protocol connectWithPassword:account.password];
    }
}
- (void)loginAccounts:(NSArray *)accounts
{
    [accounts enumerateObjectsUsingBlock:^(OTRAccount * account, NSUInteger idx, BOOL *stop) {
        [self loginAccount:account];
    }];
}

- (void)disconnectAllAccounts
{
    @synchronized(self.protocolManagerDictionary) {
        [self.protocolManagerDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id <OTRProtocol> protocol, BOOL *stop) {
            [protocol disconnect];
        }];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(connectionStatus))]) {
        OTRProtocolConnectionStatus newStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        OTRProtocolConnectionStatus oldStatus = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
        NSInteger connectedInt = 0;
        NSInteger connectingInt = 0;
        
        switch (oldStatus) {
            case OTRProtocolConnectionStatusConnected:
                connectedInt = -1;
                break;
            case OTRProtocolConnectionStatusConnecting:
                connectingInt = -1;
            default:
                break;
        }
        
        switch (newStatus) {
            case OTRProtocolConnectionStatusConnected:
                connectedInt = 1;
                break;
            case OTRProtocolConnectionStatusConnecting:
                connectedInt = 1;
            default:
                break;
        }
        
        
        self.numberOfConnectedProtocols += connectedInt;
        self.numberOfConnectingProtocols += connectingInt;
    }

}

-(BOOL)isAccountConnected:(OTRAccount *)account;
{
    id <OTRProtocol> protocol = [self.protocolManagerDictionary objectForKey:account.uniqueId];
    if (protocol) {
        return [protocol connectionStatus] == OTRProtocolConnectionStatusConnected;
    }
    return NO;
    
}


- (void)sendMessage:(OTRMessage *)message {
    
    __block OTRAccount * account = nil;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:message.buddyUniqueId transaction:transaction];
        account = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction];
        
    } completionBlock:^{
        OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
        id<OTRProtocol> protocol = [protocolManager protocolForAccount:account];
        [protocol sendMessage:message];
    }];
    
    
    
}

- (OTRPushManager *)defaultPushManager
{
    if (!self.pushManager) {
        [OTRPushAPIClient setupWithCientID:@"YXfx?hkH7Q6R5uGJu!D!gSHWRnt;jmw8pN_nlfGc" clientSecret:@"e8FuSm13xSK4drc:vMMplnc_PF_Cb92=goHyHyc;-hx-HE4xZa!90cWLwYlJxaY!ppQfFMur0Gxu6jIZxN9Wol9OXu;ogVg?zD7fdkz:4@fRkaylJGZhEqpR?:6;Mxgq"];
        self.pushManager = [[OTRPushManager alloc] init];
    }
    return self.pushManager;
}

@end
