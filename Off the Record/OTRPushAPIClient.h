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

- (void) connectAccount:(OTRPushAccount*)account successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock;

- (void) createAccount:(OTRPushAccount*)account successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock;


@end
