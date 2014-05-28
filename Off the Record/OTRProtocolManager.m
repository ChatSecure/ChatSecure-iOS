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
@property (nonatomic, strong) OTRPushManager *pushManager;

@end

@implementation OTRProtocolManager

@synthesize encryptionManager;
@synthesize protocolManagers;

- (void) dealloc 
{
    self.encryptionManager = nil;
    self.protocolManagers = nil;
}

-(id)init
{
    self = [super init];
    if(self)
    {
        self.numberOfConnectedProtocols = 0;
        self.encryptionManager = [[OTREncryptionManager alloc] init];
        self.protocolManagers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)removeProtocolManagerForAccount:(OTRAccount *)account
{
    [self.protocolManagers removeObjectForKey:account.uniqueId];
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

-(OTRBuddy *)buddyForUserName:(NSString *)buddyUserName accountName:(NSString *)accountName protocolType:(OTRProtocolType)protocolType;
{
    __block OTRBuddy *buddy = nil;
    [[OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRAccount *account =  [OTRAccount fetchAccountWithUsername:accountName protocolType:protocolType transaction:transaction];
        buddy = [OTRBuddy fetchBuddyWithUsername:buddyUserName withAccountUniqueId:account.uniqueId transaction:transaction];
    }];
   
    return buddy;
}

- (id <OTRProtocol>)protocolForAccount:(OTRAccount *)account
{
    NSObject <OTRProtocol> * protocol = [protocolManagers objectForKey:account.uniqueId];
    if(!protocol)
    {
        protocol = [[[account protocolClass] alloc] initWithAccount:account];
        if (protocol && account.uniqueId) {
            [protocolManagers setObject:protocol forKey:account.uniqueId];
            [protocol addObserver:self forKeyPath:NSStringFromSelector(@selector(connectionStatus)) options:NSKeyValueObservingOptionNew context:NULL];
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

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(connectionStatus))]) {
        OTRProtocolConnectionStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        NSInteger changeInt = 0;
        if (status == OTRProtocolConnectionStatusConnected) {
            changeInt = 1;
        }
        else if(self.numberOfConnectedProtocols > 0) {
           changeInt = -1;
        }
        
        self.numberOfConnectedProtocols += changeInt;
    }

}

-(BOOL)isAccountConnected:(OTRAccount *)account;
{
    id <OTRProtocol> protocol = [protocolManagers objectForKey:account.uniqueId];
    if (protocol) {
        return [protocol connectionStatus] == OTRProtocolConnectionStatusConnected;
    }
    return NO;
    
}


- (void)sendMessage:(OTRMessage *)message {
    
    __block OTRAccount *account = nil;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        
        OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:message.buddyUniqueId transaction:transaction];
        buddy.lastSentChatState = kOTRChatStateActive;
        [buddy saveWithTransaction:transaction];
        
        account = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction];
    }];
    
    
    OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
    id<OTRProtocol> protocol = [protocolManager protocolForAccount:account];
    [protocol sendMessage:message];
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
