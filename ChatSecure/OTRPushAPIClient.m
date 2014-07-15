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
#import "OTRPushDevice.h"

#define NSERROR_DOMAIN @"OTRPushAPIClientError"

#define SERVER_URL @"http://10.54.50.127:8000"

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
    NSURL *apiUrl = [url URLByAppendingPathComponent:@"api/"];
    if (self = [super initWithBaseURL:apiUrl]) {
        
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

- (void)removeOAuthCredentialForAccount:(OTRPushAccount *)account
{
    self.httpRequestSerializer.bearerToken = nil;
    
    [AFOAuthCredential deleteCredentialWithIdentifier:self.pushOAuthClient.clientID];
}

- (AFOAuthCredential *)oAuthCredential
{
    return [AFOAuthCredential retrieveCredentialWithIdentifier:self.pushOAuthClient.clientID];
}

#pragma - mark  oAuth Methods

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

- (void)createNewAccountWithUsername:(NSString *)username password:(NSString *)password email:(NSString *)email completion:(void (^)(OTRPushAccount *account, NSError *error))completion
{
    NSAssert(username, @"Required username");
    NSAssert(password, @"Required password");
    NSAssert(self.pushOAuthClient.clientID, @"Required clientId");
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{@"username":username,@"password":password,@"client_id":self.pushOAuthClient.clientID}];
    
    if ([email length]) {
        [parameters addEntriesFromDictionary:@{@"email":email}];
    }
    
    [self POST:@"accounts/" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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

#pragma - mark Account Methods

- (void)fetchCurrentAccount:(void (^)(OTRPushAccount *account, NSError *error))completionBlock
{
    [self refreshOAuthIfNeededWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            
            [self GET:@"accounts/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if ([responseObject isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *responseDictionary = (NSDictionary *)responseObject;
                    NSError *parseError = nil;
                    OTRPushAccount *pushAccount = [MTLJSONAdapter modelOfClass:[OTRPushAccount class] fromJSONDictionary:responseDictionary error:&parseError];
                    
                    if (completionBlock) {
                        completionBlock(pushAccount,parseError);
                    }
                    
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completionBlock) {
                    completionBlock(nil,error);
                }
            }];
            
        }
        else if(completionBlock){
            completionBlock(nil,error);
        }
    }];
}

- (void)removeOAuthTokenForAccount:(OTRPushAccount *)account
{
    [self removeOAuthCredentialForAccount:account];
}

#pragma - mark Token Methods

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

- (void)fetchAllPushTokens:(void (^)(NSArray *, NSError *))completionBlock
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
                        OTRPushToken *token = [MTLJSONAdapter modelOfClass:[OTRPushToken class] fromJSONDictionary:dictionary error:&error];
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

- (void)deletePushToken:(OTRPushToken *)token completionBlock:(void (^)(BOOL success, NSError *error))completionBlock
{
    [self refreshOAuthIfNeededWithCompletion:^(BOOL success, NSError *error) {
        if(success) {
            NSString *path = [NSString stringWithFormat:@"tokens/%@",token.serverId];
            AFHTTPRequestOperation *operation = [self DELETE:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if (completionBlock) {
                    completionBlock(YES,nil);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completionBlock) {
                    completionBlock(NO,error);
                }
            }];
            [operation start];
            
        }
        else if (completionBlock)
        {
            completionBlock(success,error);
        }
    }];
}

#pragma - mark Devie Methods

- (void)addDeviceToken:(NSData *)deviceToken name:(NSString *)name completionBlock:(void (^)(OTRPushDevice *device,NSError *error))completionBlock
{
    if (![deviceToken length]) {
        if (completionBlock) {
            completionBlock(nil,[NSError errorWithDomain:@"" code:101 userInfo:nil]);
        }
        return;
    }
    
    [self refreshOAuthIfNeededWithCompletion:^(BOOL success, NSError *error) {
        if(success) {
            
            NSString *tokenString = [OTRPushAPIClient hexStringValueWithData:deviceToken];
            
            NSDictionary *parameters = @{@"os_type":@"iOS",@"push_token":tokenString,@"os_version":[OTRPushAPIClient osVersion]};
            
            if ([name length]) {
                NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
                [mutableParameters setObject:name forKey:@"device_name"];
                parameters = [mutableParameters copy];
            }
            
            AFHTTPRequestOperation *operation = [self POST:@"devices/" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    NSError *error = nil;
                    OTRPushDevice *device = [MTLJSONAdapter modelOfClass:[OTRPushDevice class] fromJSONDictionary:responseObject error:&error];
                    
                    if (completionBlock) {
                        completionBlock(device,error);
                    }
                }
                
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completionBlock) {
                    completionBlock(nil,error);
                }
            }];
            
            [operation start];
        }
        else if (completionBlock)
        {
            completionBlock(nil,error);
        }
    }];

}

- (void)fetchAllDevices:(void (^)(NSArray *deviceArray,NSError *error))completionBlock
{
    [self refreshOAuthIfNeededWithCompletion:^(BOOL success, NSError *error) {
        
        if (success) {
            AFHTTPRequestOperation *operation = [self GET:@"devices/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *responseDictionary = (NSDictionary *)responseObject;
                    NSArray *resultArray = responseDictionary[@"results"];
                    if ([resultArray count]) {
                        __block NSError *error = nil;
                        __block NSMutableArray *deviceArray = nil;
                        [resultArray enumerateObjectsUsingBlock:^(NSDictionary *deviceDictionary, NSUInteger idx, BOOL *stop) {
                            if (!deviceArray) {
                                deviceArray = [NSMutableArray array];
                            }
                            
                            OTRPushDevice *device = [MTLJSONAdapter modelOfClass:[OTRPushDevice class] fromJSONDictionary:deviceDictionary error:&error];
                            if (device) {
                                [deviceArray addObject:device];
                            }
                            if (error) {
                                *stop = YES;
                            }
                        }];
                        
                        if (completionBlock) {
                            completionBlock([deviceArray copy],error);
                        }
                    }
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completionBlock) {
                    completionBlock(nil,error);
                }
            }];
            [operation start];
        }
        else if (completionBlock) {
            completionBlock(NO,error);
        }
    }];
}

- (void)deleteDevice:(OTRPushDevice *)device completionBlock:(void (^)(BOOL success, NSError *error))completionBlock
{
    if (!device.serverId)
    {
        if (completionBlock)
        {
            completionBlock(NO,[NSError errorWithDomain:@"" code:101 userInfo:nil]);
        }
    }
    
    [self refreshOAuthIfNeededWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            
            NSString *path = [NSString stringWithFormat:@"devices/%@",device.serverId];
            
            AFHTTPRequestOperation *operation = [self DELETE:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                if (completionBlock) {
                    completionBlock(YES,nil);
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completionBlock) {
                    completionBlock(NO,error);
                }
            }];
            [operation start];
        }
        else if (completionBlock) {
            completionBlock(success,error);
        }
    }];
    
}

#pragma - mark Utitlities
+ (NSString *)hexStringValueWithData:(NSData *)data
{
	NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([data length] * 2)];
	
    const unsigned char *dataBuffer = [data bytes];
    int i;
    
    for (i = 0; i < [data length]; ++i)
	{
        [stringBuffer appendFormat:@"%02x", (unsigned int)dataBuffer[i]];
	}
    
    return [stringBuffer copy];
}

+ (NSString *)osVersion
{
    return [[UIDevice currentDevice] systemVersion];
}


@end
