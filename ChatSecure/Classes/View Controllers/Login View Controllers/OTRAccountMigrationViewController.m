//
//  OTRAccountMigrationViewController.m
//  ChatSecure
//
//  Created by Chris Ballinger on 4/20/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "OTRAccountMigrationViewController.h"

@implementation OTRAccountMigrationViewController

- (instancetype) initWithOldAccount:(OTRAccount*)oldAccount {
    NSParameterAssert(oldAccount);
    if (self = [super initWithAccountType:oldAccount.accountType]) {
        _oldAccount = oldAccount;
    }
    return self;
}

@end
