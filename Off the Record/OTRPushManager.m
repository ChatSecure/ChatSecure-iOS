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

#import "OTRPushAccount.h"
#import "OTRPushToken.h"
#import "OTRPushDevice.h"

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
                
                [self saveObject:account transaction:transaction];
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
                [self saveObject:account transaction:transaction];
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

- (void)fetchNewPushTokenWithName:(NSString *)name completionBlock:(void (^)(OTRPushToken *, NSError *))completionBlock
{
    [[OTRPushAPIClient sharedClient] fetchNewPushTokenWithName:name completionBlock:^(OTRPushToken *pushToken, NSError *error) {
        
        if (pushToken) {
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [self saveObject:pushToken transaction:transaction];
            }];
        }
        
        if (completionBlock) {
            completionBlock(pushToken,error);
        }
        
    }];
    
}

- (void)fetchAllPushTokens:(OTRPushCompletionBlock)completionBlock
{
    [[OTRPushAPIClient sharedClient] fetchAllPushTokens:^(NSArray *tokensArray, NSError *error) {
        BOOL success = NO;
        
        if (!error) {
            success = YES;
            
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                
                [transaction removeAllObjectsInCollection:[OTRPushManager collectionForClass:[OTRPushToken class]]];
                
                [tokensArray enumerateObjectsUsingBlock:^(OTRPushToken *pushToken, NSUInteger idx, BOOL *stop) {
                    [self saveObject:pushToken transaction:transaction];
                }];
            }];
        }
        
        if (completionBlock) {
            completionBlock(success, error);
        }
    }];
}

- (void)deletePushToken:(OTRPushToken *)token completionBlock:(OTRPushCompletionBlock)completionBlock
{
    [[OTRPushAPIClient sharedClient] deletePushToken:token completionBlock:^(BOOL success, NSError *error) {
        
        if (success) {
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [self deleteObject:token transaction:transaction];
            }];
        }
        
        if (completionBlock) {
            completionBlock(success, error);
        }
    }];
}

- (void)removeOAuthTokenForAccount:(OTRPushAccount *)account
{
    [[OTRPushAPIClient sharedClient] removeOAuthTokenForAccount:account];
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
                            [self saveObject:device transaction:transaction];
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
                
                [transaction removeAllObjectsInCollection:[OTRPushManager collectionForClass:[OTRPushDevice class]]];
                
                [deviceArray enumerateObjectsUsingBlock:^(OTRPushDevice *device, NSUInteger idx, BOOL *stop) {
                    [self saveObject:device transaction:transaction];
                }];
            }];
        }
        
        if (completionBlock) {
            completionBlock(success, error);
        }
        
    }];
}

- (void)deleteDevice:(OTRPushDevice *)device completionBlock:(OTRPushCompletionBlock)completionBlock
{
    [[OTRPushAPIClient sharedClient] deleteDevice:device completionBlock:^(BOOL success, NSError *error) {
        if (success) {
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [self deleteObject:device transaction:transaction];
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
        [transaction enumerateKeysAndObjectsInCollection:[OTRPushManager collectionForClass:[OTRPushDevice class]] usingBlock:^(NSString *key, OTRPushDevice  *device, BOOL *stop) {
            if ([device.pushToken isEqualToString:token])
            {
                exists = YES;
                *stop = YES;
            }
        }];
    }];
    return exists;
}

#pragma - mark YapDatabseMethods

- (void)saveObject:(OTRPushObject *)object transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction setObject:object forKey:[OTRPushManager keyForObject:object] inCollection:[OTRPushManager collectionForObject:object]];
}

- (void)deleteObject:(OTRPushObject *)object transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction setObject:nil forKey:[OTRPushManager keyForObject:object] inCollection:[OTRPushManager collectionForObject:object]];
}

+ (NSString *)collectionForObject:(OTRPushObject *)object
{
    return [self collectionForClass:[object class]];
}

+ (NSString *)collectionForClass:(Class)class
{
    return NSStringFromClass(class);
}

+ (NSString *)keyForObject:(OTRPushObject *)object
{
    return [object.serverId stringValue];
}

#pragma - mark Class Methods


@end
