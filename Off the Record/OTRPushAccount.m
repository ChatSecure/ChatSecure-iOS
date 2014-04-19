//
//  OTRPushAccount.m
//  Off the Record
//
//  Created by Christopher Ballinger on 5/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRPushAccount.h"
#import "Strings.h"
#import "OTRPushManager.h"

#define kOTRPushAccountKey @"OTRPushAccountKey"

@implementation OTRPushAccount

- (NSString *) imageName {
    return @"ipad.png";
}

- (NSString *)providerName
{
    return @"ChatSecure Push";
}

- (Class) protocolClass {
    return [OTRPushManager class];
}

+ (OTRPushAccount*) activeAccount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    OTRPushAccount *testAccount = nil;
    NSData *accountData = [defaults objectForKey:kOTRPushAccountKey];
    if (!accountData) {
        testAccount = [[OTRPushAccount alloc] initWithAccountType:OTRAccountTypeNone];
        testAccount.username = @"test";
        testAccount.rememberPassword = YES;
        testAccount.password = @"test";
        accountData = [NSKeyedArchiver archivedDataWithRootObject:testAccount];
        [defaults setObject:accountData forKey:kOTRPushAccountKey];
    } else {
        testAccount = [NSKeyedUnarchiver unarchiveObjectWithData:accountData];
    }
    return testAccount;
}

@end
