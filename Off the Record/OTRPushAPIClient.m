//
//  OTRPushAPIClient.m
//  Off the Record
//
//  Created by Christopher Ballinger on 9/29/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRPushAPIClient.h"
#import "OTRPushAccount.h"
#import "OTRPushToken.h"
#import "OTRPushDevice.h"
#import "NSData+XMPP.h"
#import "OTRProtocolManager.h"
#import "OTRPushManager.h"
#import "OTRPUSHHTTPRequestSerializer.h"
#import "OTRPushOAuth2Client.h"

#define NSERROR_DOMAIN @"OTRPushAPIClientError"

#define SERVER_URL @"http://10.1.0.52:8000/api/"

static OTRPushAPIClient *_sharedClient = nil;

@interface OTRPushAPIClient ()

@property (nonatomic, strong) OTRPUSHHTTPRequestSerializer *httpRequestSerializer;
@property (nonatomic, strong) OTRPushOAuth2Client *pushOAuthClient;

@end

@implementation OTRPushAPIClient

- (id)initWithBaseURL:(NSURL *)url clientID:(NSString*)clientID clientSecret:(NSString*)clientSecret
{
    if (self = [self initWithBaseURL:url]) {
        self.pushOAuthClient = [[OTRPushOAuth2Client alloc] initWithBaseURL:url clientID:clientID secret:clientSecret];
    }
    return self;
}

- (id)initWithBaseURL:(NSURL *)url {
    if (self = [super initWithBaseURL:url]) {
        
        self.httpRequestSerializer = [[OTRPUSHHTTPRequestSerializer alloc] init];
        self.requestSerializer = self.httpRequestSerializer;
    }
    return self;
}

+ (void)setupWithBaseURL:(NSURL *)baseURL clientID:(NSString *)clientID clientSecret:(NSString *)clientSecret
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[OTRPushAPIClient alloc] initWithBaseURL:baseURL clientID:clientID clientSecret:clientSecret];
    });
    
    return _sharedClient;
}

+ (void)setupWithCientID:(NSString*)clientID clientSecret:(NSString*)clientSecret;
{
    NSURL *url = [NSURL URLWithString:SERVER_URL];
    [self setupWithBaseURL:url clientID:clientID clientSecret:clientSecret];
}

+ (OTRPushAPIClient *)sharedClient {
    
    NSAssert(_sharedClient != nil, @"Setup shareClient first");
    return _sharedClient;
}



- (void)setOAuthCredential:(AFOAuthCredential *)credential
{
    self.httpRequestSerializer.bearerToken = credential.accessToken;
    
    [AFOAuthCredential storeCredential:credential withIdentifier:self.pushOAuthClient.clientID withAccessibility:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
}

- (AFOAuthCredential *)oAuthCredential
{
    return [AFOAuthCredential retrieveCredentialWithIdentifier:self.pushOAuthClient.clientID];
}

- (void)refreshOAuthIfNeededWithCompletion:(void (^)(BOOL success, NSError *error))completion
{
    AFOAuthCredential *storedCredential = [self oAuthCredential];
    if (storedCredential.expired) {
        [self.pushOAuthClient authenticateUsingRefreshToken:storedCredential.refreshToken success:^(AFOAuthCredential *credential) {
            [self setOAuthCredential:credential];
            if (completion) {
                completion(YES,nil);
            }
        } failure:^(NSError *error) {
            if (completion) {
                completion(NO,error);
            }
        }];
    }
    else if (storedCredential)
    {
        [self setOAuthCredential:storedCredential];
        if (completion) {
            completion(YES,nil);
        }
    }
    else if(completion) {
        completion(NO,[NSError errorWithDomain:@"" code:101 userInfo:@{NSLocalizedDescriptionKey:@"No credential"}]);
    }
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(BOOL success, NSError *error))completion
{
    [self.pushOAuthClient authenticateUsingUsername:username password:password success:^(AFOAuthCredential *credential) {
        [self setOAuthCredential:credential];
        if (completion) {
            completion(YES,nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(NO,error);
        }
    }];
}

- (void)createNewAccountWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(OTRPushAccount *account, NSError *error))completion
{
    [self POST:@"accounts/" parameters:@{} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        OTRPushAccount *pushAccount = [MTLJSONAdapter modelOfClass:[OTRPushAccount class] fromJSONDictionary:responseObject error:&error];
        if (!error) {
            [self loginWithUsername:username password:password completion:^(BOOL success, NSError *error) {
                if (success) {
                    if (completion) {
                        completion(pushAccount,nil);
                    }
                }
                else {
                    if (completion) {
                        completion(nil,error);
                    }
                }
            }];
        }
        else{
            if (completion) {
                completion(nil,error);
            }
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil,error);
        }
    }];
}

/*

- (void) processAccount:(OTRPushAccount*)account parameters:(NSDictionary*)parameters successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    
    if (account.isRegistered) {
        if (failureBlock) {
            failureBlock([NSError errorWithDomain:NSERROR_DOMAIN code:123 userInfo:@{NSLocalizedDescriptionKey: @"Account already connected."}]);
        }
        return;
    }
    
    [self POST:@"account/" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL success = [[responseObject objectForKey:@"success"] boolValue];
            if (success) {
                OTRPushManager *pushManager = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
                pushManager.isConnected = YES;
                OTRPushAccount *localAccount = nil;
                if (successBlock) {
                    successBlock(localAccount);
                }
                [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
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

- (void) sendPushToBuddy:(OTRBuddy*)buddy successBlock:(void (^)(void))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    [self POST:@"knock/" parameters:@{@"email": buddy.username} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL success = [[responseObject objectForKey:@"success"] boolValue];
            if (success) {
                if (successBlock) {
                    successBlock();
                }
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
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}


- (void) updatePushTokenForAccount:(OTRPushAccount*)account token:(NSData *)devicePushToken successBlock:(void (^)(void))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    NSDictionary *parameters = @{@"device_type": @"iPhone", @"operating_system": @"iOS", @"apple_push_token": [devicePushToken xmpp_hexStringValue]};

    if (!account.isRegistered) {
        [self connectAccount:account password:account.password successBlock:^(OTRPushAccount *loggedInAccount) {
            NSLog(@"Account logged in: %@, updating push token...", loggedInAccount.username);
            [self updatePushTokenForAccount:loggedInAccount token:devicePushToken successBlock:successBlock failureBlock:failureBlock];
        } failureBlock:failureBlock];
        return;
    }
    [self POST:@"device/" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Token updated: %@", responseObject);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL success = [[responseObject objectForKey:@"success"] boolValue];
            if (success) {
                if (successBlock) {
                    successBlock();
                }
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
}*/

- (void)fetchNewPushTokenWithName:(NSString *)name completionBlock:(void (^)(OTRPushToken *, NSError *))completionBlock
{
    [self refreshOAuthIfNeededWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSDictionary * parameters = nil;
            if ([name length]) {
                parameters = @{@"name":name};
            }
            
            AFHTTPRequestOperation *operation = [self POST:@"tokens/" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    NSError *error = nil;
                    OTRPushToken *token = [MTLJSONAdapter modelOfClass:token.class fromJSONDictionary:responseObject error:&error];
                    if (error) {
                        if (completionBlock) {
                            completionBlock(nil,error);
                        }
                    }
                    else if(completionBlock)
                    {
                        completionBlock(token,nil);
                    }
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completionBlock) {
                    completionBlock(nil,error);
                }
            }];
            [operation start];
        }
        else if(completionBlock)
        {
            completionBlock(nil,error);
        }
        
    }];
}

- (void)fetchAllPushTokensCompletinoBlock:(void (^)(NSArray *, NSError *))completionBlock
{
    [self refreshOAuthIfNeededWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            AFHTTPRequestOperation *operation = [self GET:@"tokens/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                if ([responseObject isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *responseDictionary = (NSDictionary *)responseObject;
                    NSArray *tokensJSONArray = [responseDictionary objectForKey:@"results"];
                    NSMutableArray *tokens = [NSMutableArray array];
                    __block NSError *error = nil;
                    [tokensJSONArray enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger idx, BOOL *stop) {
                        OTRPushToken *token = [MTLJSONAdapter modelOfClass:token.class fromJSONDictionary:dictionary error:&error];
                        if (error || !token) {
                            *stop = YES;
                        }
                        else {
                            [tokens addObject:token];
                        }
                    }];
                    
                    if (error) {
                        if (completionBlock) {
                            completionBlock(nil,error);
                        }
                    }
                    else if (completionBlock) {
                        completionBlock([tokens copy],nil);
                    }
                    
                    
                    
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                if (completionBlock) {
                    completionBlock(nil,error);
                }
                
            }];
            [operation start];
        }
        else if(completionBlock)
        {
            completionBlock(nil,error);
        }
        
    }];
}


@end
