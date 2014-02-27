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
#import "OTRManagedAccount.h"
#import "OTRConstants.h"
#import "OTRManagedOscarAccount.h"
#import "OTRManagedXMPPAccount.h"

#import "OTRLog.h"

@interface OTRAccountsManager(Private)
- (void) refreshAccountsArray;
@end

@implementation OTRAccountsManager

+ (void) removeAccount:(OTRManagedAccount*)account {
    if (!account) {
        DDLogWarn(@"Account is nil!");
        return;
    }
    account.password = nil;
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRManagedAccount * acct = (OTRManagedAccount *)[context existingObjectWithID:account.objectID error:nil];
    
    [acct prepareBuddiesandMessagesForDeletion];
    [acct MR_deleteEntity];
    
    [context MR_saveToPersistentStoreAndWait];
    
   
}

+ (NSArray *)allAccountsAbleToAddBuddies  {
    NSArray * allAccountsArray = [OTRManagedAccount MR_findAllSortedBy:OTRManagedAccountAttributes.username ascending:YES];
    NSPredicate * connectedFilter = [NSPredicate predicateWithFormat:@"%K == YES",@"isConnected"];
    NSPredicate * facebookFilter = [NSPredicate predicateWithFormat:@"%K != %d",NSStringFromSelector(@selector(accountType)),OTRAccountTypeFacebook];
    NSPredicate * predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[connectedFilter,facebookFilter]];
    return [allAccountsArray filteredArrayUsingPredicate:predicate];
}

+(OTRManagedAccount *)accountForProtocol:(NSString *)protocol accountName:(NSString *)accountName inContext:(NSManagedObjectContext *)context
{
    NSPredicate * accountFilter = [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@",OTRManagedAccountAttributes.protocol,protocol,OTRManagedAccountAttributes.username,accountName];
    NSArray * results = [OTRManagedAccount MR_findAllWithPredicate:accountFilter inContext:context];
    
    
    OTRManagedAccount * fetchedAccount = nil;
    if (results) {
        fetchedAccount = [results firstObject];
    }
    return fetchedAccount;
}

+ (NSArray *)allAutoLoginAccounts
{
    NSPredicate * autoLoginPredicate = [NSPredicate predicateWithFormat:@"%K == YES",OTRManagedAccountAttributes.autologin];
    
    NSArray * accounts = [OTRManagedAccount MR_findAllWithPredicate:autoLoginPredicate];
    
    return accounts;
}



@end
