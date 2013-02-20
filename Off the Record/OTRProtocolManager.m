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
#import "OTRManagedBuddy.h"
#import "OTRConstants.h"

static OTRProtocolManager *sharedManager = nil;

@implementation OTRProtocolManager

@synthesize encryptionManager;
@synthesize settingsManager;
@synthesize accountsManager;
@synthesize protocolManagers;

- (void) dealloc 
{
    self.encryptionManager = nil;
    self.settingsManager = nil;
    self.accountsManager = nil;
    self.protocolManagers = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRSendMessage object:nil];
}

-(id)init
{
    self = [super init];
    if(self)
    {
        self.accountsManager = [[OTRAccountsManager alloc] init];
        self.encryptionManager = [[OTREncryptionManager alloc] init];
        self.settingsManager = [[OTRSettingsManager alloc] init];
        self.protocolManagers = [[NSMutableDictionary alloc] init];

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(sendMessage:)
         name:kOTRSendMessage
         object:nil ];
        
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

-(void)sendMessage:(NSNotification *)notification
{
    NSObject *messageObject = [notification object];
    if ([messageObject isKindOfClass:[OTRManagedMessage class]]) {
        OTRManagedMessage *message = (OTRManagedMessage *)messageObject;
        [message send];
    }        
}

-(OTRManagedBuddy *)buddyForUserName:(NSString *)buddyUserName accountName:(NSString *)accountName protocol:(NSString *)protocol
{
    OTRManagedAccount * account = [self.accountsManager accountForProtocol:protocol accountName:accountName];
    return [OTRManagedBuddy fetchOrCreateWithName:buddyUserName account:account];
}

- (id <OTRProtocol>)protocolForAccount:(OTRManagedAccount *)account
{
    id <OTRProtocol> protocol = [protocolManagers objectForKey:account.uniqueIdentifier];
    if(!protocol)
    {
        protocol = [[[account protocolClass] alloc] init];
        protocol.account = account;
        [protocolManagers setObject:protocol forKey:account.uniqueIdentifier];
    }
    return protocol;
}

-(BOOL)isAccountConnected:(OTRManagedAccount *)account;
{
    id <OTRProtocol> protocol = [protocolManagers objectForKey:account.uniqueIdentifier];
    if (protocol) {
        return [protocol isConnected];
    }
    return NO;
    
}

@end
