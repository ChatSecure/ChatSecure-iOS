//
//  OTRPushController.m
//  Off the Record
//
//  Created by Christopher Ballinger on 9/28/12.
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

#import "OTRPushController.h"
#import "OTRPushAPIClient.h"
#import "NSData+XMPP.h"
#import "SSKeychain.h"
#import "OTRConstants.h"
#import "OTRProtocolManager.h"


#define REGISTER_PATH @"register"
#define ADD_DPT_PATH @"add_dpt"
#define REQUEST_PAT_PATH @"request_pat"
#define KNOCK_PATH @"knock"

#define kOTRPushAccountKey @"kOTRPushAccountKey"

#define ACCOUNT_ID_KEY @"account_id"
#define PASSWORD_KEY @"password"
#define EXPIRATION_DATE_KEY @"expiration_date"
#define DPT_KEY @"dpt"
#define PAT_KEY @"pat"
#define PATS_KEY @"pats"
#define PAT_NAME_KEY @"name"
#define ACCOUNTS_KEY @"accounts"
#define RESET_KEY @"reset"
#define RECEIPT_KEY @"receipt-data"

#define LOCAL_PAT_KEY @"local_pat"
#define REMOTE_PAT_KEY @"remote_pat"
#define REMOTE_ACCOUNT_ID_KEY @"account_id"
#define LOCAL_PATS_KEY @"local_pats"
#define PAT_DICTIONARY_KEY @"pats"

@implementation OTRPushController
@synthesize pushClient;

- (id) init {
    if (self = [super init]) {
        self.pushClient = [OTRPushAPIClient sharedClient];
    }
    return self;
}

+ (OTRPushController*)sharedInstance
{
    static dispatch_once_t once;
    static OTRPushController *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[OTRPushController alloc] init];
    });
    return sharedInstance;
}

+ (void) registerForPushNotifications {
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
}


- (void) registerWithReceipt:(NSData*)receipt resetAccount:(BOOL)resetAccount {
    NSString *receiptString = [receipt base64Encoded];
    //NSLog(@"Receipt bytes: %@", [receipt description]);
    if (!receiptString) {
        NSLog(@"Receipt string is nil!");
        return;
    }
    //NSLog(@"Receipt string: %@", receiptString);
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:receiptString forKey:RECEIPT_KEY];
    [parameters setObject:@(resetAccount) forKey:RESET_KEY];
    [pushClient postPath:REGISTER_PATH parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"response: %@", [responseObject description]);
        NSString *accountID = [responseObject objectForKey:ACCOUNT_ID_KEY];
        NSString *password = [responseObject objectForKey:PASSWORD_KEY];
        NSString *expirationDateString = [responseObject objectForKey:EXPIRATION_DATE_KEY];
        if (accountID && password && expirationDateString) {
            NSMutableDictionary *accountDictionary = [self accountDictionary];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy-MM-dd";
            NSDate *expirationDate = [dateFormatter dateFromString:expirationDateString];
            [accountDictionary setObject:accountID forKey:ACCOUNT_ID_KEY];
            [accountDictionary setObject:expirationDate forKey:EXPIRATION_DATE_KEY];
            [self saveAccountDictionary:accountDictionary];
            self.password = password;
            [[NSNotificationCenter defaultCenter] postNotificationName:kOTRPushAccountUpdateNotification object:self];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error registering with receipt: %@%@", [error localizedDescription], [error userInfo]);
    }];
}

- (NSString*) accountID {
    return [[self accountDictionary] objectForKey:ACCOUNT_ID_KEY];
}

- (NSString*) password {
    NSError *error = nil;
    NSString *password = [SSKeychain passwordForService:kOTRServiceName account:[self accountID] error:&error];
    if (error) {
        NSLog(@"Error retreiving password from keychain: %@", [error userInfo]);
    }
    return password;
}

- (void) setPassword:(NSString *)password {
    NSError *error = nil;
    [SSKeychain setPassword:password forService:kOTRServiceName account:[self accountID] error:&error];
    if (error) {
        NSLog(@"Error storing password in keychain: %@", [error userInfo]);
    }
}

- (NSDate*) expirationDate {
    return [[self accountDictionary] objectForKey:EXPIRATION_DATE_KEY];
}

- (NSArray*) pats {
    NSDictionary *accountDictionary = [self accountDictionary];
    return [accountDictionary objectForKey:PATS_KEY];
}

- (NSArray*) accountIDs {
    NSDictionary *accountDictionary = [self accountDictionary];
    return [accountDictionary objectForKey:ACCOUNTS_KEY];
}

- (NSMutableDictionary*) accountDictionary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *productDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kOTRPushAccountKey]];
    if (!productDictionary) {
        productDictionary = [NSMutableDictionary dictionary];
    }
    return productDictionary;
}

- (NSArray*) buddies {
    NSMutableArray *buddyArray = [NSMutableArray array];
    
    NSMutableDictionary *accountDictionary = [self accountDictionary];
    
    NSDictionary *patsDictionary = [accountDictionary objectForKey:PATS_KEY];
    NSArray *protocols = [patsDictionary allKeys];
    for (NSString *protocol in protocols) {
        NSDictionary *accountsDictionary = [patsDictionary objectForKey:protocol];
        NSArray *accounts = [accountsDictionary allKeys];
        for (NSString *account in accounts) {
            NSDictionary *usersDictionary = [accountsDictionary objectForKey:account];
            NSArray *usernames = [usersDictionary allKeys];
            for (NSString *username in usernames) {
                OTRManagedBuddy *buddy = [[OTRProtocolManager sharedInstance] buddyForUserName:username accountName:account protocol:protocol];
                if (buddy) {
                    [buddyArray addObject:buddy];
                }
            }
        }
    }
    return buddyArray;
}

- (void) saveAccountDictionary:(NSMutableDictionary*)productsDictionary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:productsDictionary forKey:kOTRPushAccountKey];
    BOOL success = [defaults synchronize];
    if (!success) {
        NSLog(@"Product preferences not saved to disk!");
    }
}

- (BOOL) checkSubscriptionStatus {    
    NSString *accountID = [self accountID];
    NSString *password = [self password];
    NSDate *expirationDate = [self expirationDate];
    
    if (!accountID || !password) {
        return NO;
    }
    
    BOOL subscriptionExpired = [expirationDate compare:[NSDate date]] == NSOrderedAscending;
    if (subscriptionExpired) {
        NSLog(@"Push subscription expired on: %@", [expirationDate description]);
        return NO;
    }
    return YES;
}

- (void) updateDevicePushToken:(NSData *)devicePushToken {
    if (![self checkSubscriptionStatus]) {
        return;
    }
    NSString *accountID = [self accountID];
    NSString *password = [self password];
    NSMutableDictionary *postDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
    NSString *dpt = [devicePushToken hexStringValue];
    [postDictionary setObject:dpt forKey:DPT_KEY];
    [postDictionary setObject:accountID forKey:ACCOUNT_ID_KEY];
    [postDictionary setObject:password forKey:PASSWORD_KEY];
    
    [pushClient postPath:ADD_DPT_PATH parameters:postDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Updated device push token: %@", dpt);
        NSLog(@"Response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error updating device push token: %@%@", [error localizedDescription], [error userInfo]);
    }];
}

- (NSMutableDictionary*) patDictionaryForBuddy:(OTRManagedBuddy*)buddy {
    NSMutableDictionary *patsAccountDictionary = [self patAccountsDictionaryForBuddy:buddy];
    NSMutableDictionary *patsUserDictionary = [NSMutableDictionary dictionaryWithDictionary:[patsAccountDictionary objectForKey:buddy.accountName]];
    if (!patsUserDictionary) {
        patsUserDictionary = [NSMutableDictionary dictionary];
    }
    return patsUserDictionary;
}

- (NSMutableDictionary*) patAccountsDictionaryForBuddy:(OTRManagedBuddy*)buddy {
    NSMutableDictionary *patsProtocolDictionary = [self patsProtocolDictionaryForBuddy:buddy];
    NSMutableDictionary *patsAccountDictionary = [NSMutableDictionary dictionaryWithDictionary:[patsProtocolDictionary objectForKey:buddy.account.username]];
    if (!patsAccountDictionary) {
        patsAccountDictionary = [NSMutableDictionary dictionary];
    }
    return patsAccountDictionary;
}

- (NSMutableDictionary*) patsProtocolDictionaryForBuddy:(OTRManagedBuddy*)buddy {
    NSMutableDictionary *accountDictionary = [self accountDictionary];
    
    NSMutableDictionary *patsDictionary = [NSMutableDictionary dictionaryWithDictionary:[accountDictionary objectForKey:PATS_KEY]];
    if (!patsDictionary) {
        patsDictionary = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *patsProtocolDictionary = [NSMutableDictionary dictionaryWithDictionary:[patsDictionary objectForKey:buddy.account.protocol]];
    if (!patsProtocolDictionary) {
        patsProtocolDictionary = [NSMutableDictionary dictionary];
    }
    return patsProtocolDictionary;
}

- (void) setPatDictionary:(NSMutableDictionary*)patDictionary forBuddy:(OTRManagedBuddy*)buddy {
    NSMutableDictionary *accountDictionary = [self accountDictionary];
    NSMutableDictionary *patsDictionary = [NSMutableDictionary dictionaryWithDictionary:[accountDictionary objectForKey:PATS_KEY]];
    
    NSMutableDictionary *patsProtocolDictionary = [self patsProtocolDictionaryForBuddy:buddy];
    NSMutableDictionary *patsAccountDictionary = [self patAccountsDictionaryForBuddy:buddy];
    [patsAccountDictionary setObject:patDictionary forKey:buddy.accountName];
    [patsProtocolDictionary setObject:patsAccountDictionary forKey:buddy.account.username];
    [patsDictionary setObject:patsProtocolDictionary forKey:buddy.account.protocol];
    [accountDictionary setObject:patsDictionary forKey:PATS_KEY];
    [self saveAccountDictionary:accountDictionary];
}

- (void) setLocalPAT:(NSString*)pat forBuddy:(OTRManagedBuddy*)buddy {
    NSMutableDictionary *patDictionary = [self patDictionaryForBuddy:buddy];
    
    if (pat) {
        [patDictionary setObject:pat forKey:LOCAL_PAT_KEY];
        [self setName:buddy.displayName forLocalPAT:pat];
    } else {
        [patDictionary removeObjectForKey:LOCAL_PAT_KEY];
        [self setName:nil forLocalPAT:pat];
    }
    
    [self setPatDictionary:patDictionary forBuddy:buddy];
}

- (NSString*) nameForLocalPAT:(NSString*)pat {
    NSMutableDictionary *accountDictionary = [self accountDictionary];
    NSMutableDictionary *localPatsDictionary = [NSMutableDictionary dictionaryWithDictionary:[accountDictionary objectForKey:LOCAL_PATS_KEY]];
    if (!localPatsDictionary) {
        localPatsDictionary = [NSMutableDictionary dictionary];
    }
    return [localPatsDictionary objectForKey:pat];
}

- (void) setName:(NSString*)name forLocalPAT:(NSString*)localPAT {
    NSMutableDictionary *accountDictionary = [self accountDictionary];
    NSMutableDictionary *localPatsDictionary = [NSMutableDictionary dictionaryWithDictionary:[accountDictionary objectForKey:LOCAL_PATS_KEY]];
    if (!localPatsDictionary) {
        localPatsDictionary = [NSMutableDictionary dictionary];
    }
    if (name) {
        [localPatsDictionary setObject:name forKey:localPAT];
    } else {
        [localPatsDictionary removeObjectForKey:localPAT];
    }
    [accountDictionary setObject:localPatsDictionary forKey:LOCAL_PATS_KEY];
    [self saveAccountDictionary:accountDictionary];
}

- (NSString*) localPATForBuddy:(OTRManagedBuddy*)buddy {
    NSMutableDictionary *patDictionary = [self patDictionaryForBuddy:buddy];
    return [patDictionary objectForKey:LOCAL_PAT_KEY];
}

- (NSString*) remotePATForBuddy:(OTRManagedBuddy*)buddy {
    NSMutableDictionary *patDictionary = [self patDictionaryForBuddy:buddy];
    return [patDictionary objectForKey:REMOTE_PAT_KEY];
}

- (NSString*) accountIDForBuddy:(OTRManagedBuddy*)buddy {
    NSMutableDictionary *patDictionary = [self patDictionaryForBuddy:buddy];
    return [patDictionary objectForKey:ACCOUNT_ID_KEY];
}

- (void) setRemotePAT:(NSString*)pat accountID:(NSString*)accountID forBuddy:(OTRManagedBuddy*)buddy {
    NSMutableDictionary *patDictionary = [self patDictionaryForBuddy:buddy];
    
    [patDictionary setObject:pat forKey:REMOTE_PAT_KEY];
    [patDictionary setObject:accountID forKey:REMOTE_ACCOUNT_ID_KEY];
    
    [self setPatDictionary:patDictionary forBuddy:buddy];
}

- (void) requestPushAccessTokenForBuddy:(OTRManagedBuddy*)buddy {
    if (![self checkSubscriptionStatus]) {
        return;
    }
    NSString *accountID = [self accountID];
    NSString *password = [self password];
    NSMutableDictionary *postDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    [postDictionary setObject:accountID forKey:ACCOUNT_ID_KEY];
    [postDictionary setObject:password forKey:PASSWORD_KEY];
        
    [pushClient postPath:REQUEST_PAT_PATH parameters:postDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"PAT Request Response: %@", responseObject);
        NSString *pat = [responseObject objectForKey:PAT_KEY];
        if (!pat || !pat.length) {
            return;
        }
        [self setLocalPAT:pat forBuddy:buddy];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error requesting PAT: %@%@", [error localizedDescription], [error userInfo]);
    }];
}

- (void) knockWithAccountID:(NSString*)accountID pat:(NSString*)pat {
    
    NSMutableDictionary *postDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    [postDictionary setObject:accountID forKey:ACCOUNT_ID_KEY];
    [postDictionary setObject:pat forKey:PAT_KEY];
    
    [pushClient postPath:KNOCK_PATH parameters:postDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Knock Response: %@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error sending knock: %@%@", [error localizedDescription], [error userInfo]);
    }];
}

- (void) refreshActivePats {}

@end
