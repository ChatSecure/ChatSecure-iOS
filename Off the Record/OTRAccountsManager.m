//
//  OTRAccountsManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 6/26/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
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

#import "OTRAccountsManager.h"
#import "OTRSettingsManager.h"
#import "OTRAccount.h"
#import "OTRConstants.h"
#import "OTROscarAccount.h"
#import "OTRXMPPAccount.h"

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
            
            OTRAccount *account = nil;
            if ([[settingsDictionary objectForKey:kOTRAccountProtocolKey] isEqualToString:kOTRProtocolTypeXMPP]) {
                account = [[OTRXMPPAccount alloc] initWithSettingsDictionary:settingsDictionary uniqueIdentifier:settingKey];
            } else if ([[settingsDictionary objectForKey:kOTRAccountProtocolKey] isEqualToString:kOTRProtocolTypeAIM]) {
                account = [[OTROscarAccount alloc] initWithSettingsDictionary:settingsDictionary uniqueIdentifier:settingKey];
            }

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
