//
//  OTRPushController.h
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

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "OTRPushAPIClient.h"
#import "OTRManagedBuddy.h"

@interface OTRPushController : NSObject

@property (nonatomic, assign) OTRPushAPIClient *pushClient;


- (void) registerWithReceipt:(NSData*)receipt resetAccount:(BOOL)resetAccount;
- (void) updateDevicePushToken:(NSData*)devicePushToken;
- (void) requestPushAccessTokenForBuddy:(OTRManagedBuddy*)buddy;
- (void) knockWithAccountID:(NSString*)accountID pat:(NSString*)pat;
- (void) refreshActivePats;

- (NSArray*) buddies; // returns array of OTRBuddys that are participating

@property (nonatomic, readonly) NSString *accountID;
@property (nonatomic, readonly) NSString *password;
@property (nonatomic, readonly) NSDate *expirationDate;

+ (void) registerForPushNotifications;

+ (OTRPushController*) sharedInstance;

// For getting human-readable names for recieved PATs in push messages
- (NSString*) nameForLocalPAT:(NSString*)pat;
- (void) setName:(NSString*)name forLocalPAT:(NSString*)localPAT;


- (void) setLocalPAT:(NSString*)pat forBuddy:(OTRManagedBuddy*)buddy;
- (void) setRemotePAT:(NSString*)pat accountID:(NSString*)accountID forBuddy:(OTRManagedBuddy*)buddy;
- (NSString*) localPATForBuddy:(OTRManagedBuddy*)buddy;
- (NSString*) remotePATForBuddy:(OTRManagedBuddy*)buddy;
- (NSString*) accountIDForBuddy:(OTRManagedBuddy*)buddy;

@end
