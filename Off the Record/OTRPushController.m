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

#define SERVER_URL @"http://push.chatsecure.org:5000/"

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

+ (NSURL*) baseURL {
    return [NSURL URLWithString:SERVER_URL];
}

- (void) registerWithReceipt:(NSData*)receipt {
    NSString *receiptString = [receipt base64Encoded];
    //NSLog(@"Receipt bytes: %@", [receipt description]);
    if (!receiptString) {
        NSLog(@"Receipt string is nil!");
        return;
    }
    //NSLog(@"Receipt string: %@", receiptString);
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:receiptString forKey:@"receipt-data"];
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
            [accountDictionary setObject:password forKey:PASSWORD_KEY]; // TODO: store this in the keychain
            [accountDictionary setObject:expirationDate forKey:EXPIRATION_DATE_KEY];
            [self saveAccountDictionary:accountDictionary];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error registering with receipt: %@%@", [error localizedDescription], [error userInfo]);
    }];
}

- (NSString*) accountID {
    return [[self accountDictionary] objectForKey:ACCOUNT_ID_KEY];
}

- (NSString*) password {
    return [[self accountDictionary] objectForKey:PASSWORD_KEY];
}

- (NSDate*) expirationDate {
    return [[self accountDictionary] objectForKey:EXPIRATION_DATE_KEY];
}

- (NSArray*) pats {
    NSDictionary *accountDictionary = [self accountDictionary];
    return [accountDictionary objectForKey:PATS_KEY];
}

- (NSArray*) accountIDs {
    return nil;
}

- (NSMutableDictionary*) accountDictionary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *productDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kOTRPushAccountKey]];
    if (!productDictionary) {
        productDictionary = [NSMutableDictionary dictionary];
    }
    return productDictionary;
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
    NSMutableDictionary *accountDictionary = [self accountDictionary];
    
    NSString *accountID = [accountDictionary objectForKey:ACCOUNT_ID_KEY];
    NSString *password = [accountDictionary objectForKey:PASSWORD_KEY];
    NSDate *expirationDate = [accountDictionary objectForKey:EXPIRATION_DATE_KEY];
    
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
    NSMutableDictionary *accountDictionary = [self accountDictionary];
    NSString *accountID = [accountDictionary objectForKey:ACCOUNT_ID_KEY];
    NSString *password = [accountDictionary objectForKey:PASSWORD_KEY];
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

- (void) requestPushAccessTokenForBuddy:(OTRBuddy*)buddy {
    if (![self checkSubscriptionStatus]) {
        return;
    }
    NSMutableDictionary *accountDictionary = [self accountDictionary];
    NSString *accountID = [accountDictionary objectForKey:ACCOUNT_ID_KEY];
    NSString *password = [accountDictionary objectForKey:PASSWORD_KEY];
    NSMutableDictionary *postDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    [postDictionary setObject:accountID forKey:ACCOUNT_ID_KEY];
    [postDictionary setObject:password forKey:PASSWORD_KEY];
        
    [pushClient postPath:REQUEST_PAT_PATH parameters:postDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"PAT Request Response: %@", responseObject);
        NSString *pat = [responseObject objectForKey:PAT_KEY];
        if (!pat || !pat.length) {
            return;
        }
        NSMutableArray *patsArray = [NSMutableArray arrayWithArray:[accountDictionary objectForKey:PATS_KEY]];
        if (!patsArray) {
            patsArray = [NSMutableArray array];
        }
        NSString *displayName = buddy.displayName;
        if (!displayName) {
            displayName = @"???";
        }
        
        NSMutableDictionary *patsDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [patsDictionary setObject:buddy.accountName forKey:PAT_NAME_KEY];
        [patsDictionary setObject:pat forKey:PAT_KEY];
        [patsArray addObject:patsDictionary];
        [accountDictionary setObject:patsArray forKey:PATS_KEY];
        [self saveAccountDictionary:accountDictionary];
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

@end
