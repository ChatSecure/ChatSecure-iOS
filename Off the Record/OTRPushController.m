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

#define SERVER_URL @"http://192.168.1.44:5000/"

#define REGISTER_PATH @"register"
#define ADD_DPT_PATH @"add_dpt"

#define kOTRPushAccountKey @"kOTRPushAccountKey"

#define ACCOUNT_ID_KEY @"account_id"
#define PASSWORD_KEY @"password"
#define EXPIRATION_DATE_KEY @"expiration_date"
#define DPT_KEY @"dpt"

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

- (void) registerWithReceipt:(NSData*)receipt transactionIdentifier:(NSString*)transactionIdentifier {
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

- (void) updateDevicePushToken:(NSData *)devicePushToken {
    NSMutableDictionary *accountDictionary = [self accountDictionary];

    NSString *accountID = [accountDictionary objectForKey:ACCOUNT_ID_KEY];
    NSString *password = [accountDictionary objectForKey:PASSWORD_KEY];
    NSDate *expirationDate = [accountDictionary objectForKey:EXPIRATION_DATE_KEY];
    
    if (!accountID || !password) {
        return;
    }
    
    BOOL subscriptionExpired = [expirationDate compare:[NSDate date]] == NSOrderedAscending;
    if (subscriptionExpired) {
        NSLog(@"Push subscription expired on: %@", [expirationDate description]);
        return;
    }
    
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

@end
