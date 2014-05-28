//
//  OTRPushManager.m
//  Off the Record
//
//  Created by Christopher Ballinger on 5/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRPushManager.h"
#import "OTRConstants.h"
#import "OTRPushAPIClient.h"

#import "OTRDatabaseManager.h"

#import "OTRYapPushAccount.h"
#import "OTRYapPushToken.h"
#import "OTRYapPushTokenOwned.h"
#import "OTRYapPushDevice.h"

@interface OTRPushManager()

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;

@end

@implementation OTRPushManager

- (id)init
{
    if (self = [super init]) {
        self.databaseConnection = [OTRDatabaseManager sharedInstance].readWriteDatabaseConnection;
    }
    return self;
}

- (void)createNewAccountWithUsername:(NSString *)username password:(NSString *)password emial:(NSString *)email completion:(OTRPushCompletionBlock)completion
{
    [[OTRPushAPIClient sharedClient] createNewAccountWithUsername:username password:password email:email completion:^(OTRPushAccount *account, NSError *error) {
        
        BOOL success = NO;
        
        if (!error) {
            success = YES;
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                
                OTRYapPushAccount *yapPushAccount = [[OTRYapPushAccount alloc] initWithPushAccount:account];
                [yapPushAccount saveWithTransaction:transaction];
            }];
        }
        
        if (completion) {
            completion(success,error);
        }
    }];
}

- (void)refreshCurrentAccount:(OTRPushCompletionBlock)completion
{
    [[OTRPushAPIClient sharedClient] fetchCurrentAccount:^(OTRPushAccount *account, NSError *error) {
        
        BOOL success = NO;
        
        if (!error) {
            success = YES;
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                OTRYapPushAccount *pushAccount = [[OTRYapPushAccount alloc] initWithPushAccount:account];
                [pushAccount saveWithTransaction:transaction];
            }];
        }
        
        if (completion) {
            completion(success,error);
        }
        
    }];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(OTRPushCompletionBlock)completionBlock
{
    [[OTRPushAPIClient sharedClient] loginWithUsername:username password:password completion:^(BOOL success, NSError *error) {
        if (success) {
            [self refreshCurrentAccount:^(BOOL success, NSError *error) {
                if (completionBlock) {
                    completionBlock(success,error);
                }
            }];
        }
        else if (completionBlock) {
            completionBlock(success,error);
        }
    }];
}

#pragma - mark Token Methods

- (void)fetchNewPushTokenWithName:(NSString *)name completionBlock:(void (^)(OTRYapPushTokenOwned *, NSError *))completionBlock
{
    [[OTRPushAPIClient sharedClient] fetchNewPushTokenWithName:name completionBlock:^(OTRPushToken *pushToken, NSError *error) {
        
        __block OTRYapPushTokenOwned *yapPushToken = nil;
        if (pushToken) {
            
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                yapPushToken = [[OTRYapPushTokenOwned alloc] initWithPushToken:pushToken];
                yapPushToken.accountUniqueId = [OTRYapPushAccount currentAccountWithTransaction:transaction].uniqueId;
                [yapPushToken saveWithTransaction:transaction];
            }];
        }
        
        if (completionBlock) {
            completionBlock(yapPushToken,error);
        }
        
    }];
    
}

- (void)deletePushToken:(OTRYapPushToken *)token completionBlock:(OTRPushCompletionBlock)completionBlock
{
    [[OTRPushAPIClient sharedClient] deletePushToken:token.pushToken completionBlock:^(BOOL success, NSError *error) {
        
        if (success) {
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [token removeWithTransaction:transaction];
            }];
        }
        
        if (completionBlock) {
            completionBlock(success, error);
        }
    }];
}

- (void)removeOAuthTokenForAccount:(OTRYapPushAccount *)account
{
    [[OTRPushAPIClient sharedClient] removeOAuthTokenForAccount:account.pushAccount];
}

#pragma - makr Device Methods

- (void)addDeviceToken:(NSData *)deviceToken name:(NSString *)name completionBlock:(OTRPushCompletionBlock)completionBlock
{
    //check if it's already on the server
    [self fetchAllDevices:^(BOOL success, NSError *error) {
        if (success) {
            
            if ([self existsDeviceWithToken:[OTRPushAPIClient hexStringValueWithData:deviceToken]])
            {
                if (completionBlock) {
                    completionBlock(YES,nil);
                }
            }
            else {
                [[OTRPushAPIClient sharedClient] addDeviceToken:deviceToken name:name completionBlock:^(OTRPushDevice *device, NSError *error) {
                    BOOL success = NO;
                    if (device) {
                        success = YES;
                        [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                            OTRYapPushDevice *yapPushDevice = [[OTRYapPushDevice alloc] initWithPushDevice:device];
                            yapPushDevice.accountUniqueId = [OTRYapPushAccount currentAccountWithTransaction:transaction].uniqueId;
                            [yapPushDevice saveWithTransaction:transaction];
                        }];
                    }
                    
                    
                    if (completionBlock) {
                        completionBlock(success,error);
                    }
                    
                }];
            }
            
            
        }
        else if(completionBlock)
        {
            completionBlock(success,error);
        }
    }];
}

- (void)fetchAllDevices:(OTRPushCompletionBlock)completionBlock
{
    [[OTRPushAPIClient sharedClient] fetchAllDevices:^(NSArray *deviceArray, NSError *error) {
        BOOL success = NO;
        if (!error) {
            success = YES;
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                
                [transaction removeAllObjectsInCollection:[OTRYapPushDevice collection]];
                
                [deviceArray enumerateObjectsUsingBlock:^(OTRPushDevice *device, NSUInteger idx, BOOL *stop) {
                    OTRYapPushDevice *yapPushDevice = [[OTRYapPushDevice alloc] initWithPushDevice:device];
                    yapPushDevice.accountUniqueId = [OTRYapPushAccount currentAccountWithTransaction:transaction].uniqueId;
                    
                    [yapPushDevice saveWithTransaction:transaction];
                }];
            }];
        }
        
        if (completionBlock) {
            completionBlock(success, error);
        }
        
    }];
}

- (void)deleteDevice:(OTRYapPushDevice *)device completionBlock:(OTRPushCompletionBlock)completionBlock
{
    [[OTRPushAPIClient sharedClient] deleteDevice:device.pushDevice completionBlock:^(BOOL success, NSError *error) {
        if (success) {
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [device removeWithTransaction:transaction];
            }];
        }
        
        if (completionBlock) {
            completionBlock(success,error);
        }
    }];
}

- (BOOL)existsDeviceWithToken:(NSString *)token
{
    __block BOOL exists = NO;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[OTRYapPushDevice collection] usingBlock:^(NSString *key, OTRYapPushDevice  *device, BOOL *stop) {
            if ([device.pushDevice.pushToken isEqualToString:token])
            {
                exists = YES;
                *stop = YES;
            }
        }];
    }];
    return exists;
}

#pragma - mark Class Methods


@end
