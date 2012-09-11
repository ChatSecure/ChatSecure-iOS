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
#import "OTRBuddy.h"
#import "OTRConstants.h"

static OTRProtocolManager *sharedManager = nil;

@implementation OTRProtocolManager

@synthesize encryptionManager;
@synthesize buddyList;
@synthesize settingsManager;
@synthesize accountsManager;
@synthesize protocolManagers;

- (void) dealloc 
{
    self.encryptionManager = nil;
    self.buddyList = nil;
    self.settingsManager = nil;
    self.accountsManager = nil;
    self.protocolManagers = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRSendMessage object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRBuddyListUpdate object:nil];
}

-(id)init
{
    self = [super init];
    if(self)
    {
        self.accountsManager = [[OTRAccountsManager alloc] init];
        self.encryptionManager = [[OTREncryptionManager alloc] init];
        self.settingsManager = [[OTRSettingsManager alloc] init];
        self.buddyList = [[OTRBuddyList alloc] init];
        self.protocolManagers = [[NSMutableDictionary alloc] init];

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(sendMessage:)
         name:kOTRSendMessage
         object:nil ];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(buddyListUpdate)
         name:kOTRBuddyListUpdate
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
    if ([messageObject isKindOfClass:[OTRMessage class]]) {
        OTRMessage *message = (OTRMessage *)messageObject;
        [message send];

    }
        
    //NSLog(@"send message (%@): %@", protocol, message.message);
}


-(void)buddyListUpdate
{
    NSLog(@"Protocols: %@",[protocolManagers allKeys]);
    for (id key in protocolManagers) {
        [self.buddyList updateBuddies:[[protocolManagers objectForKey:key] buddyList]];
    }
    
    
}

-(OTRBuddy *)buddyForUserName:(NSString *)buddyUserName accountName:(NSString *)accountName protocol:(NSString *)protocol
{
    return [self.buddyList getBuddyForUserName:buddyUserName accountUniqueIdentifier:[self.accountsManager accountForProtocol:protocol accountName:accountName].uniqueIdentifier];
    
    
}

- (id <OTRProtocol>)protocolForAccount:(OTRAccount *)account
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

@end
