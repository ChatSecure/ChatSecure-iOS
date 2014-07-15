//
//  OTRPushManager.h
//  Off the Record
//
//  Created by Christopher Ballinger on 5/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTRYapPushTokenOwned;
@class OTRYapPushToken;
@class OTRYapPushDevice;
@class OTRYapPushAccount;


typedef void (^OTRPushCompletionBlock)(BOOL success, NSError *error);

@interface OTRPushManager : NSObject

#pragma - mark Account Methods

- (void)createNewAccountWithUsername:(NSString *)username password:(NSString *)password emial:(NSString *)email completion:(OTRPushCompletionBlock)completion;

- (void)refreshCurrentAccount:(OTRPushCompletionBlock)completion;

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(OTRPushCompletionBlock)completionBlock;

- (void)removeOAuthTokenForAccount:(OTRYapPushAccount *)account;

#pragma - mark Token Methods

- (void)fetchNewPushTokenWithName:(NSString *)name completionBlock:(void (^)(OTRYapPushTokenOwned *pushToken, NSError *error))completionBlock;

// don't need to fetch all tokens from server syncing tokens should be done directly to device to device to maintain buddy connections
//- (void)fetchAllPushTokens:(OTRPushCompletionBlock)completionBlock;

- (void)deletePushToken:(OTRYapPushToken *)token completionBlock:(OTRPushCompletionBlock)completionBlock;

#pragma - mark Device Methods

- (void)addDeviceToken:(NSData *)deviceToken name:(NSString *)name completionBlock:(OTRPushCompletionBlock)completionBlock;

- (void)fetchAllDevices:(OTRPushCompletionBlock)completionBlock;

- (void)deleteDevice:(OTRYapPushDevice *)device completionBlock:(OTRPushCompletionBlock)completionBlock;

@end
