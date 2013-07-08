//
//  OTRPushAPIClient.h
//  Off the Record
//
//  Created by Christopher Ballinger on 9/29/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "AFHTTPClient.h"
#import "OTRPushAccount.h"

@interface OTRPushAPIClient : AFHTTPClient

+ (OTRPushAPIClient*) sharedClient;

- (void) connectAccount:(OTRPushAccount*)account password:(NSString*)password successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock;

- (void) createAccount:(OTRPushAccount*)account password:(NSString*)password successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock;

- (void) sendPushToBuddy:(OTRManagedBuddy*)buddy successBlock:(void (^)(void))successBlock failureBlock:(void (^)(NSError *error))failureBlock;

- (void) updatePushTokenForAccount:(OTRPushAccount*)account token:(NSData *)devicePushToken successBlock:(void (^)(void))successBlock failureBlock:(void (^)(NSError *error))failureBlock;


@end
