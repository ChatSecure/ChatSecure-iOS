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
    self.parameterEncoding = AFJSONParameterEncoding;
    
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
    [self postPath:@"account/" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        NSError *error = nil;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL success = [[responseObject objectForKey:@"success"] boolValue];
            if (success) {
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                    OTRPushAccount *localAccount = [account MR_inContext:localContext];
                    localAccount.isConnected = @(YES);
                } completion:^(BOOL success, NSError *error) {
                    if (success) {
                        if (successBlock) {
                            NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
                            OTRPushAccount *localAccount = [account MR_inContext:localContext];
                            successBlock(localAccount);
                        }
                    } else {
                        if (failureBlock) {
                            failureBlock(error);
                        }
                    }
                }];
            } else {
                error = [NSError errorWithDomain:@"OTRPushAPIClientError" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Success is false.", @"data": responseObject}];
            }
        } else {
            error = [NSError errorWithDomain:@"OTRPushAPIClientError" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Response object not dictionary.", @"data": responseObject}];
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

- (void) connectAccount:(OTRPushAccount*)account successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    [self processAccount:account parameters:@{@"email": account.username, @"password": account.password} successBlock:successBlock failureBlock:failureBlock];
}

- (void) createAccount:(OTRPushAccount*)account successBlock:(void (^)(OTRPushAccount* loggedInAccount))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    [self processAccount:account parameters:@{@"email": account.username, @"password": account.password, @"create": @(YES)} successBlock:successBlock failureBlock:failureBlock];
}



@end
