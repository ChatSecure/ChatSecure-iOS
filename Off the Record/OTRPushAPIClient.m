//
//  OTRPushAPIClient.m
//  Off the Record
//
//  Created by Christopher Ballinger on 9/29/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRPushAPIClient.h"
#import "AFJSONRequestOperation.h"
#import "OTRPushController.h"
#import "OTRPushAccount.h"
#import "NSData+XMPP.h"

#define NSERROR_DOMAIN @"OTRPushAPIClientError"

#define SERVER_URL @"http://192.168.1.115:8000/api/"


@implementation OTRPushAPIClient

+ (OTRPushAPIClient *)sharedClient {
    static OTRPushAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[OTRPushAPIClient alloc] initWithBaseURL:[NSURL URLWithString:SERVER_URL]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    //self.parameterEncoding = AFJSONParameterEncoding;
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

- (NSMutableURLRequest*) requestWithMethod:(NSString*)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
    request.HTTPShouldHandleCookies = YES;
    return request;
}

- (void) processAccount:(OTRPushAccount*)account parameters:(NSDictionary*)parameters successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    if (account.isConnectedValue) {
        if (failureBlock) {
            failureBlock([NSError errorWithDomain:NSERROR_DOMAIN code:123 userInfo:@{NSLocalizedDescriptionKey: @"Account already connected."}]);
        }
        return;
    }
    [self postPath:@"account/" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        NSError *error = nil;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL success = [[responseObject objectForKey:@"success"] boolValue];
            if (success) {
                NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
                OTRPushAccount *localAccount = (OTRPushAccount*)[localContext existingObjectWithID:account.objectID error:nil];
                localAccount.isConnected = @(YES);
                [localContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error){
                    if (!error) {
                        if (successBlock) {
                            NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
                            OTRPushAccount *localAccount = (OTRPushAccount*)[localContext existingObjectWithID:account.objectID error:nil];
                            successBlock(localAccount);
                            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
                        }
                    } else {
                        if (failureBlock) {
                            failureBlock(error);
                        }
                    }
                }];
            } else {
                error = [NSError errorWithDomain:NSERROR_DOMAIN code:100 userInfo:@{NSLocalizedDescriptionKey: @"Success is false.", @"data": responseObject}];
            }
        } else {
            error = [NSError errorWithDomain:NSERROR_DOMAIN code:102 userInfo:@{NSLocalizedDescriptionKey: @"Response object not dictionary.", @"data": responseObject}];
        }
        if (error && failureBlock) {
            failureBlock(error);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (error && failureBlock) {
            failureBlock(error);
        }
    }];
}

- (void) connectAccount:(OTRPushAccount*)account password:(NSString*)password successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    [self processAccount:account parameters:@{@"email": account.username, @"password": password} successBlock:successBlock failureBlock:failureBlock];
}

- (void) createAccount:(OTRPushAccount*)account password:(NSString*)password successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    [self processAccount:account parameters:@{@"email": account.username, @"password": password, @"create": @(YES)} successBlock:successBlock failureBlock:failureBlock];
}

- (void) sendPushFromAccount:(OTRPushAccount*)account toBuddy:(OTRManagedBuddy*)buddy successBlock:(void (^)(void))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    
}

- (void) updatePushTokenForAccount:(OTRPushAccount*)account token:(NSData *)devicePushToken successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    if (!account.isConnectedValue) {
        [self connectAccount:account password:account.password successBlock:successBlock failureBlock:failureBlock];
        return;
    }
    NSDictionary *parameters = @{@"device_type": @"iPhone", @"operating_system": @"iOS", @"apple_push_token": [devicePushToken hexStringValue]};
    [self postPath:@"device/" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL success = [[responseObject objectForKey:@"success"] boolValue];
            if (success) {
                NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
                OTRPushAccount *localAccount = [account MR_inContext:localContext];
                successBlock(localAccount);
                return;
            }
        }
        if (failureBlock) {
            failureBlock([NSError errorWithDomain:NSERROR_DOMAIN code:101 userInfo:@{NSLocalizedDescriptionKey: @"Data is not good!", @"data": responseObject}]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}

@end
