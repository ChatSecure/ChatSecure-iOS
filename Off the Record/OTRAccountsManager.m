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
@synthesize accounts;

- (void) dealloc {
    self.accounts = nil;
}

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *accountsDictionary = [defaults objectForKey:kOTRSettingAccountsKey];
        NSArray *values = [accountsDictionary allValues];
        NSArray *keys = [accountsDictionary allKeys];
        int count = [values count];
        self.accounts = [NSMutableArray arrayWithCapacity:count];
        for (int i = 0; i < count; i++) {
            NSDictionary *settingsDictionary = [values objectAtIndex:i];
            NSString *settingKey = [keys objectAtIndex:i];
            OTRAccount *account = [[OTRAccount alloc] initWithSettingsDictionary:settingsDictionary uniqueIdentifier:settingKey];
            [accounts addObject:account];
        }
    }
    return self;
}

@end
