//
//  OTRPushManager.h
//  Off the Record
//
//  Created by Christopher Ballinger on 5/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTRPushToken;
@class OTRPushDevice;
@class OTRPushObject;

typedef void (^OTRPushCompletionBlock)(BOOL success, NSError *error);

@interface OTRPushManager : NSObject

#pragma - mark Account Methods

- (void)createNewAccountWithUsername:(NSString *)username password:(NSString *)password completion:(OTRPushCompletionBlock)completion;

- (void)refreshCurrentAccount:(OTRPushCompletionBlock)completion;

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(OTRPushCompletionBlock)completionBlock;

#pragma - mark Token Methods

- (void)fetchNewPushTokenWithName:(NSString *)name completionBlock:(void (^)(OTRPushToken *pushToken, NSError *error))completionBlock;

- (void)fetchAllPushTokens:(OTRPushCompletionBlock)completionBlock;

- (void)deletePushToken:(OTRPushToken *)token completionBlock:(OTRPushCompletionBlock)completionBlock;

#pragma - mark Device Methods

- (void)addDeviceToken:(NSData *)deviceToken name:(NSString *)name completionBlock:(OTRPushCompletionBlock)completionBlock;

- (void)fetchAllDevices:(OTRPushCompletionBlock)completionBlock;

- (void)deleteDevice:(OTRPushDevice *)device completionBlock:(OTRPushCompletionBlock)completionBlock;

#pragma - mark Class Methods
+ (NSString *)collectionForObject:(OTRPushObject *)object;

+ (NSString *)collectionForClass:(Class)class;

+ (NSString *)keyForObject:(OTRPushObject *)object;

@end