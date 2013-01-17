//
//  OTRConvertAccount.m
//  Off the Record
//
//  Created by David on 1/16/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRConvertAccount.h"
#import "OTRSettingsManager.h"

@implementation OTRConvertAccount



+(BOOL)hasLegacyAccountSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *accountsDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kOTRSettingAccountsKey]];
    
    if(accountsDictionary)
        return YES;
    else
        return NO;
    
}

+(void)saveDictionary:(NSDictionary *)accountDictionary;
{
    NSLog(@"Converting: %@",accountDictionary); 
    
}

+(BOOL)convertAllLegacyAcountSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *accountsDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kOTRSettingAccountsKey]];
    
    if (accountsDictionary) {
        for(id key in accountsDictionary)
        {
            NSDictionary * accountDictionary = [accountsDictionary objectForKey:key];
            [OTRConvertAccount saveDictionary:accountDictionary];
        }
        //[defaults removeObjectForKey:kOTRSettingAccountsKey];
    }
}


@end
