//
//  test_OTRPushAPIClient.m
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OTRPushOAuth2Client.h"
#import "TRVSMonitor.h"
#import "OTRPushAPIClient.h"

NSString *baseURLString = @"http://192.168.1.30:8000";
NSString *clientID = @"5sv8gm89NZvObnhJsTKm2-ixy@uGR7gzcA-pQR6I";
NSString *clientSecret = @"Uku0Yxc7WwdTCBvfMgK_!-XnpjVtjkOrT7@Af7hwKEWq8_SS8Nvszgh=V=tqbhV_q9-sf?dKK.G;HWpyx!dzhPma:kv-6zxj!mEC-x?X@@63dq!2t._uGUmJS3EhvmJd";

@interface test_OTRPushAPIClient : XCTestCase

@property (nonatomic, strong) OTRPushAPIClient *client;

@end

@implementation test_OTRPushAPIClient

- (void)setUp
{
    [super setUp];
    
    self.client = [[OTRPushAPIClient alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",baseURLString,@"/api"]] clientID:clientID clientSecret:clientSecret];
    
    //[OTRPushAPIClient sharedClient].bearerToken = @"asdf";
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)test_OAUTH2Client
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    NSURL *baseUrl = [NSURL URLWithString:baseURLString];
    __block NSError *error = nil;
    __block AFOAuthCredential *cred = nil;
    
    OTRPushOAuth2Client *oauthClient = [[OTRPushOAuth2Client alloc] initWithBaseURL:baseUrl clientID:clientID secret:clientSecret];
    
    [oauthClient authenticateUsingUsername:@"bob" password:@"bob" success:^(AFOAuthCredential *credential) {
        cred = credential;
        [monitor signal];
    } failure:^(NSError *err) {
        error = err;
        [monitor signal];
    }];
    
    [monitor waitWithTimeout:100.0];
    
    XCTAssertNotNil(cred,@"Credential is nil");
    XCTAssertNil(error, @"Error: %@",error);
}

- (void)test_APILogin
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block BOOL sucessResult = NO;
    __block NSError *errorResult = nil;
    [self.client loginWithUsername:@"bob" password:@"bob" completion:^(BOOL success, NSError *error) {
        sucessResult = success;
        errorResult = error;
        [monitor signal];
    }];
    
    [monitor waitWithTimeout:100];
    
    XCTAssertNil(errorResult, @"Error: %@",errorResult);
    XCTAssertTrue(sucessResult, @"Not successful");
}

- (void)test_FetchTokens
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    __block NSArray *tokens = nil;
    __block NSError *errorResult = nil;
    [self.client fetchAllPushTokensCompletinoBlock:^(NSArray *tokensArray, NSError *error) {
        tokens = tokensArray;
        errorResult = error;
        [monitor signal];
    }];
    
    [monitor waitWithTimeout:100];
    
    XCTAssertNil(errorResult, @"Error: %@",errorResult);
    XCTAssertNotNil(tokens, @"No tokens");
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

@end
