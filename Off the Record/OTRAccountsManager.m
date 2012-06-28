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
@synthesize accountsDictionary, accountsArray;

- (void) dealloc {
    self.accountsDictionary = nil;
    accountsArray = nil;
}

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *rawAccountsDictionary = [defaults objectForKey:kOTRSettingAccountsKey];
        NSArray *values = [rawAccountsDictionary allValues];
        NSArray *keys = [rawAccountsDictionary allKeys];
        int count = [values count];
        self.accountsDictionary = [NSMutableDictionary dictionaryWithCapacity:count];
        for (int i = 0; i < count; i++) {
            NSDictionary *settingsDictionary = [values objectAtIndex:i];
            NSString *settingKey = [keys objectAtIndex:i];
            OTRAccount *account = [[OTRAccount alloc] initWithSettingsDictionary:settingsDictionary uniqueIdentifier:settingKey];
            [accountsDictionary setObject:account forKey:account.uniqueIdentifier];
        }
    }
    return self;
}

- (void) addAccount:(OTRAccount*)account {
    if (!account) {
        NSLog(@"Account is nil!");
        return;
    }
    [accountsDictionary setObject:account forKey:account.uniqueIdentifier];    
    [account save];
}

- (void) removeAccount:(OTRAccount*)account {
    if (!account) {
        NSLog(@"Account is nil!");
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *rawAcountsDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kOTRSettingAccountsKey]];
    
    [rawAcountsDictionary removeObjectForKey:account.uniqueIdentifier];
    [defaults setObject:rawAcountsDictionary forKey:kOTRSettingAccountsKey];
    [accountsDictionary removeObjectForKey:account.uniqueIdentifier];
}

- (NSArray*) accountsArray {
    if (accountsArray && [accountsArray count] == [accountsDictionary count]) {
        return accountsArray;
    }
    NSArray *accounts = [accountsDictionary allValues];
    NSSortDescriptor *sortDescriptor =  [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [accounts sortedArrayUsingDescriptors:sortDescriptors];
    accountsArray = sortedArray;
    return accountsArray;
}

@end
