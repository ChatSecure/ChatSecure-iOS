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
#import "OTROscarManager.h"
#import "OTRManagedBuddy.h"
#import "OTRManagedOAuthAccount.h"
#import "OTRConstants.h"

#import "OTRLog.h"

static OTRProtocolManager *sharedManager = nil;

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
        _numberOfConnectedProtocols = 0;
        self.encryptionManager = [[OTREncryptionManager alloc] init];
        self.protocolManagers = [[NSMutableDictionary alloc] init];
    }
    return self;
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

-(OTRManagedBuddy *)buddyForUserName:(NSString *)buddyUserName accountName:(NSString *)accountName protocol:(NSString *)protocol inContext:(NSManagedObjectContext *)context
{
    OTRManagedAccount * account = [OTRAccountsManager accountForProtocol:protocol accountName:accountName inContext:context];
    OTRManagedBuddy * buddy = [OTRManagedBuddy fetchOrCreateWithName:buddyUserName account:account inContext:context];
    [context MR_saveToPersistentStoreAndWait];
    return buddy;
}

- (id <OTRProtocol>)protocolForAccount:(OTRManagedAccount *)account
{
    NSObject <OTRProtocol> * protocol = [protocolManagers objectForKey:account.uniqueIdentifier];
    if(!protocol)
    {
        protocol = [[[account protocolClass] alloc] initWithAccount:account];
        if (protocol && account.uniqueIdentifier) {
            [protocolManagers setObject:protocol forKey:account.uniqueIdentifier];
            [protocol addObserver:self forKeyPath:NSStringFromSelector(@selector(isConnected)) options:NSKeyValueObservingOptionNew context:NULL];
        }
    }
    return protocol;
}

- (void)loginAccount:(OTRManagedAccount *)account
{
    id <OTRProtocol> protocol = [self protocolForAccount:account];
    if( [account conformsToProtocol:@protocol(OTRManagedOAuthAccountProtocol)])
    {
        [((OTRManagedAccount <OTRManagedOAuthAccountProtocol> *) account) refreshToken:^(NSError *error) {
            if (!error) {
                [protocol connectWithPassword:((OTRManagedAccount <OTRManagedOAuthAccountProtocol> *) account).accessTokenString];
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
    [accounts enumerateObjectsUsingBlock:^(OTRManagedAccount * account, NSUInteger idx, BOOL *stop) {
        [self loginAccount:account];
    }];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(isConnected))]) {
        BOOL isConnected = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        NSInteger changeInt = 0;
        if (isConnected) {
            changeInt = 1;
        }
        else if(self.numberOfConnectedProtocols > 0) {
           changeInt = -1;
        }
        
        if (change != 0) {
            [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfConnectedProtocols))];
            _numberOfConnectedProtocols += changeInt;
            [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfConnectedProtocols))];
        }
    }

}

-(BOOL)isAccountConnected:(OTRManagedAccount *)account;
{
    id <OTRProtocol> protocol = [protocolManagers objectForKey:account.uniqueIdentifier];
    if (protocol) {
        return [protocol isConnected];
    }
    return NO;
    
}

+ (void)sendMessage:(OTRManagedMessage *)message {
    message.buddy.lastMessageDisconnectedValue = NO;
    message.buddy.lastSentChatStateValue=kOTRChatStateActive;
    [[message managedObjectContext] MR_saveToPersistentStoreAndWait];
    [message.buddy invalidatePausedChatStateTimer];
    //FIXME
    
    OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
    id<OTRProtocol> protocol = [protocolManager protocolForAccount:message.buddy.account];
    [protocol sendMessage:message];
}

@end
