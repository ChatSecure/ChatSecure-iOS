//
//  OTRPushAPIClient.h
//  Off the Record
//
//  Created by Christopher Ballinger on 9/29/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "AFNetworking.h"

@class OTRPushAccount;
@class OTRPushToken;

@interface OTRPushAPIClient : AFHTTPRequestOperationManager

- (id)initWithBaseURL:(NSURL *)url clientID:(NSString*)clientID clientSecret:(NSString*)clientSecret;

////// Login //////

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(BOOL success, NSError *error))completion;

- (void)createNewAccountWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(OTRPushAccount *account, NSError *error))completion;

////// Push Tokens //////

- (void)fetchNewPushTokenWithName:(NSString *)name completionBlock:(void (^)(OTRPushToken *pushToken, NSError *error))completionBlock;

- (void)fetchAllPushTokensCompletinoBlock:(void (^)(NSArray *tokensArray, NSError *error))completionBlock;

////// Singleton Methods //////

+ (void)setupWithBaseURL:(NSURL *)baseURL clientID:(NSString*)clientID clientSecret:(NSString*)clientSecret;
+ (void)setupWithCientID:(NSString*)clientID clientSecret:(NSString*)clientSecret;

+ (OTRPushAPIClient*)sharedClient;

//- (void) connectAccount:(OTRPushAccount*)account password:(NSString*)password successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock;
//
//- (void) createAccount:(OTRPushAccount*)account password:(NSString*)password successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock;
//
//- (void) sendPushToBuddy:(OTRBuddy*)buddy successBlock:(void (^)(void))successBlock failureBlock:(void (^)(NSError *error))failureBlock;
//
//- (void) updatePushTokenForAccount:(OTRPushAccount*)account token:(NSData *)devicePushToken successBlock:(void (^)(void))successBlock failureBlock:(void (^)(NSError *error))failureBlock;



@end
