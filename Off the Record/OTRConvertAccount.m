//
//  OTRConvertAccount.m
//  Off the Record
//
//  Created by David on 1/16/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRConvertAccount.h"
#import "OTRSettingsManager.h"
#import "OTROldXMPPAccount.h"
#import "OTROldOscarAccount.h"
#import "OTRManagedXMPPAccount.h"
#import "OTRManagedOscarAccount.h"
#import "OTRConstants.h"


@implementation OTRConvertAccount



-(BOOL)hasLegacyAccountSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *accountsDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kOTRSettingAccountsKey]];
    
    if(accountsDictionary)
        return YES;
    else
        return NO;
    
}

-(void)saveDictionary:(NSDictionary *)accountDictionary withUniqueId:(NSString *)uniqueId;
{
    //DDLogVerbose(@"Converting: %@",accountDictionary);
    NSString * protocol = [accountDictionary objectForKey:kOTRAccountProtocolKey];
    if ([protocol isEqualToString:kOTRProtocolTypeXMPP]) {
        OTRXMPPAccount * xmppAccount = [[OTRXMPPAccount alloc] initWithSettingsDictionary:accountDictionary uniqueIdentifier:uniqueId];
        
        OTRManagedXMPPAccount * managagedXmppAccount = [OTRManagedXMPPAccount MR_createEntity];
        
        managagedXmppAccount.uniqueIdentifier = xmppAccount.uniqueIdentifier;
        [managagedXmppAccount setUsername:xmppAccount.username];
        managagedXmppAccount.domain = xmppAccount.domain;
        [managagedXmppAccount setPortValue:xmppAccount.port];
        managagedXmppAccount.protocol = xmppAccount.protocol;
        [managagedXmppAccount setRememberPasswordValue:xmppAccount.rememberPassword];
        managagedXmppAccount.password = xmppAccount.password;
        
        
        NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
        [context MR_saveToPersistentStoreAndWait];
        
        
        
    }
    else if([protocol isEqualToString:kOTRProtocolTypeAIM])
    {
        OTROscarAccount * oscarAccount = [[OTROscarAccount alloc] initWithSettingsDictionary:accountDictionary uniqueIdentifier:uniqueId];
        
        OTRManagedOscarAccount * managedOscarAccount = [OTRManagedOscarAccount MR_createEntity];
        
        managedOscarAccount.protocol = oscarAccount.protocol;
        managedOscarAccount.password = oscarAccount.password;
        managedOscarAccount.uniqueIdentifier = managedOscarAccount.uniqueIdentifier;
        [managedOscarAccount setUsername:oscarAccount.username];
        [managedOscarAccount setRememberPasswordValue:oscarAccount.rememberPassword];
        
        NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
        [context MR_saveToPersistentStoreAndWait];
        
        
        
        
        
    }
    
    
}

-(BOOL)convertAllLegacyAcountSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *accountsDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kOTRSettingAccountsKey]];
    
    if (accountsDictionary) {
        for(NSString * key in accountsDictionary)
        {
            NSDictionary * accountDictionary = [accountsDictionary objectForKey:key];
            [self saveDictionary:accountDictionary withUniqueId:key];
        }
        NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
        [context MR_saveToPersistentStoreAndWait];
        [defaults removeObjectForKey:kOTRSettingAccountsKey];
    }
}


@end
