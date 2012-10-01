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

#define SERVER_URL @"http://192.168.1.82:5000/"
#define REGISTER_PATH @"register"

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
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error registering with receipt: %@%@", [error localizedDescription], [error userInfo]);
    }];
}

- (void) updateDevicePushToken:(NSData *)devicePushToken {
    NSLog(@"Updated device push token: %s", [devicePushToken bytes]);
}

@end
