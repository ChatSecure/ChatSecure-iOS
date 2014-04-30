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
#import "OTRConstants.h"
#import "OTRProtocolManager.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseConnection.h"
#import "YapDatabaseTransaction.h"
#import "OTRLog.h"
#import "OTRAccount.h"
#import "OTRPushAccount.h"

@interface OTRAccountsManager(Private)
- (void) refreshAccountsArray;
@end

@implementation OTRAccountsManager

+ (void)removeAccount:(OTRAccount*)account
{
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        [transaction setObject:nil forKey:account.uniqueId inCollection:[OTRAccount collection]];
    }];
}

+ (NSArray *)allAccountsAbleToAddBuddies  {
    
    __block NSArray *accounts = nil;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        accounts = [OTRAccount allAccountsWithTransaction:transaction];
    }];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        
        if ([evaluatedObject isKindOfClass:[OTRAccount class]]) {
            OTRAccount *account = (OTRAccount *)evaluatedObject;
            
            if (account.accountType != OTRAccountTypeFacebook && [[OTRProtocolManager sharedInstance] isAccountConnected:account]) {
                return YES;
            }
        }
        return NO;
    }];
    
    
    return [accounts filteredArrayUsingPredicate:predicate];
}

+ (OTRAccount *)accountWithUsername:(NSString *)username protocolType:(OTRProtocolType)protocolType
{
    __block OTRAccount *account = nil;
    [[OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [OTRAccount fetchAccountWithUsername:username protocolType:protocolType transaction:transaction];
    }];
    return account;
}

+ (NSArray *)allAutoLoginAccounts
{
    __block NSArray *accounts = nil;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        accounts = [OTRAccount allAccountsWithTransaction:transaction];
    }];

    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        if ([evaluatedObject isKindOfClass:[OTRAccount class]]) {
            OTRAccount *account = (OTRAccount *)evaluatedObject;
            if (account.accountType != OTRAccountTypeXMPPTor && account.autologin) {
                return YES;
            }
            
        }
        return NO;
    }];
    
    return [accounts filteredArrayUsingPredicate:predicate];
}

+ (OTRPushAccount *)defaultPushAccount
{
    __block OTRPushAccount *account = nil;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        NSArray *keys = [transaction allKeysInCollection:NSStringFromClass([OTRPushAccount class])];
        
        if ([keys count]) {
            account = [transaction objectForKey:[keys firstObject] inCollection:NSStringFromClass([OTRPushAccount class])];
        }
    }];
    
    return account;
}



@end
