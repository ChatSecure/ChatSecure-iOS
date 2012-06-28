//
//  OTRProtocolManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

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
    OTRMessage *message = [notification object];
    [message send];
    
    //NSLog(@"send message (%@): %@", protocol, message.message);
}


-(void)buddyListUpdate
{
    NSLog(@"Protocols: %@",[protocolManagers allKeys]);
    for (id key in protocolManagers) {
        [self.buddyList updateBuddies:[[protocolManagers objectForKey:key] buddyList]];
    }
    
    
}

-(id<OTRProtocol>)protocolForAccountName:(NSString *)accountName
{
    id<OTRProtocol> protocol;
    for(id key in protocolManagers)
    {
        if ([((id <OTRProtocol>)[protocolManagers objectForKey:key]).account.username isEqualToString:accountName])
            return [protocolManagers objectForKey:key];
    }
    return protocol;
}

-(OTRBuddy *)buddyByUserName:(NSString *)buddyUserName accountName:(NSString *)accountName
{
    return [self.buddyList getbuddyByUserName:buddyUserName accountUniqueIdentifier:[self protocolForAccountName:buddyUserName].account.uniqueIdentifier];
    
    
}

- (id <OTRProtocol>)protocolForAccount:(OTRAccount *)account
{
    id <OTRProtocol> protocol = [protocolManagers objectForKey:account.uniqueIdentifier];
    if(!protocol)
    {
        if([account.protocol isEqualToString:kOTRProtocolTypeAIM])
        {
            protocol = [[OTROscarManager alloc] init];
        }
        else if([account.protocol isEqualToString:kOTRProtocolTypeXMPP])
        {
            protocol = [[OTRXMPPManager alloc] init];
        }
        protocol.account = account;
        [protocolManagers setObject:protocol forKey:account.uniqueIdentifier];
    }
    return protocol;
}

@end
