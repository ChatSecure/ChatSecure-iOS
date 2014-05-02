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
@class OTRPushDevice;

@interface OTRPushAPIClient : AFHTTPRequestOperationManager

- (id)initWithBaseURL:(NSURL *)url clientID:(NSString*)clientID clientSecret:(NSString*)clientSecret;

////// Login //////

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(BOOL success, NSError *error))completionBlock;

- (void)createNewAccountWithUsername:(NSString *)username password:(NSString *)password email:(NSString *)email completion:(void (^)(OTRPushAccount *account, NSError *error))completion;

- (void)removeOAuthTokenForAccount:(OTRPushAccount *)account;

////// Account //////

- (void)fetchCurrentAccount:(void (^)(OTRPushAccount *account, NSError *error))completionBlock;

////// Push Tokens //////

- (void)fetchNewPushTokenWithName:(NSString *)name completionBlock:(void (^)(OTRPushToken *pushToken, NSError *error))completionBlock;

- (void)fetchAllPushTokens:(void (^)(NSArray *tokensArray, NSError *error))completionBlock;

- (void)deletePushToken:(OTRPushToken *)token completionBlock:(void (^)(BOOL success, NSError *error))completionBlock;

////// Devices //////

- (void)addDeviceToken:(NSData *)deviceToken name:(NSString *)name completionBlock:(void (^)(OTRPushDevice *device,NSError *error))completionBlock;

- (void)fetchAllDevices:(void (^)(NSArray *deviceArray,NSError *error))completionBlock;

- (void)deleteDevice:(OTRPushDevice *)device completionBlock:(void (^)(BOOL success, NSError *error))completionBlock;

////// Singleton Methods //////

+ (void)setupWithBaseURL:(NSURL *)baseURL clientID:(NSString*)clientID clientSecret:(NSString*)clientSecret;

+ (void)setupWithCientID:(NSString*)clientID clientSecret:(NSString*)clientSecret;

+ (OTRPushAPIClient*)sharedClient;

////// Utiity Methods //////

+ (NSString *)hexStringValueWithData:(NSData *)data;

@end
