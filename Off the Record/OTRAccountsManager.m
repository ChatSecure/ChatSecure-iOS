//
//  OTRAccountsManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 6/26/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRAccountsManager.h"
#import "OTRSettingsManager.h"
#import "OTRAccount.h"

@implementation OTRAccountsManager
@synthesize accountsDictionary, accountsArray, reverseLookupDictionary;

- (void) dealloc {
    self.accountsDictionary = nil;
    self.accountsArray = nil;
}

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *rawAccountsDictionary = [defaults objectForKey:kOTRSettingAccountsKey];
        reverseLookupDictionary = [[NSMutableDictionary alloc] init];
        NSArray *values = [rawAccountsDictionary allValues];
        NSArray *keys = [rawAccountsDictionary allKeys];
        int count = [values count];
        self.accountsDictionary = [NSMutableDictionary dictionaryWithCapacity:count];
        for (int i = 0; i < count; i++) {
            NSDictionary *settingsDictionary = [values objectAtIndex:i];
            NSString *settingKey = [keys objectAtIndex:i];
            OTRAccount *account = [[OTRAccount alloc] initWithSettingsDictionary:settingsDictionary uniqueIdentifier:settingKey];
            [accountsDictionary setObject:account forKey:account.uniqueIdentifier];
            [reverseLookupDictionary setObject:[NSMutableDictionary dictionaryWithObject:account forKey:account.username] forKey:account.protocol];
        }
        [self refreshAccountsArray];
    }
    return self;
}

- (void) addAccount:(OTRAccount*)account {
    if (!account) {
        NSLog(@"Account is nil!");
        return;
    }
    [accountsDictionary setObject:account forKey:account.uniqueIdentifier];    
    [reverseLookupDictionary setObject:[NSMutableDictionary dictionaryWithObject:account forKey:account.username] forKey:account.protocol];
    [account save];
    [self refreshAccountsArray];
}

- (void) removeAccount:(OTRAccount*)account {
    if (!account) {
        NSLog(@"Account is nil!");
        return;
    }
    account.password = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *rawAcountsDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kOTRSettingAccountsKey]];
    
    [rawAcountsDictionary removeObjectForKey:account.uniqueIdentifier];
    [defaults setObject:rawAcountsDictionary forKey:kOTRSettingAccountsKey];
    [accountsDictionary removeObjectForKey:account.uniqueIdentifier];
    [[reverseLookupDictionary objectForKey:account.protocol] removeObjectForKey:account.username];
    [self refreshAccountsArray];
    [defaults synchronize];
}

- (void) refreshAccountsArray {
    NSArray *accounts = [accountsDictionary allValues];
    NSSortDescriptor *sortDescriptor =  [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [accounts sortedArrayUsingDescriptors:sortDescriptors];
    self.accountsArray = sortedArray;
}

-(OTRAccount *)accountForProtocol:(NSString *)protocol accountName:(NSString *)accountName
{
    return [[reverseLookupDictionary objectForKey:protocol] objectForKey:accountName];
}

@end
