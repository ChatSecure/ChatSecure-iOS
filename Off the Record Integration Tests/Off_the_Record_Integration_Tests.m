//
//  Off_the_Record_Integration_Tests.m
//  Off the Record Integration Tests
//
//  Created by David Chiles on 11/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <SenTestingKit/SenTestingKit.h>

#import "OTRManagedFacebookAccount.h"
#import "OTRManagedGoogleAccount.h"
#import "OTRManagedXMPPAccount.h"
#import "OTRManagedOscarAccount.h"
#import "OTRTestSecrets.h"
#import "OTRProtocolManager.h"




@interface Off_the_Record_Integration_Tests : XCTestCase

@end

@implementation Off_the_Record_Integration_Tests
{
    BOOL didConnect;
    BOOL hasCalledBack;
}

- (void)setUp
{
    [super setUp];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(protocolLoginFailed:)
     name:kOTRProtocolLoginFail
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(protocolLoginSuccess:)
     name:kOTRProtocolLoginSuccess
     object:nil ];
    
    [MagicalRecord setDefaultModelFromClass:[self class]];
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
}

- (void)tearDown
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRProtocolLoginFail object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRProtocolLoginSuccess object:nil];
    [MagicalRecord cleanUp];
    [super tearDown];
}

- (void)test_GoogleAccount {
    OTRManagedGoogleAccount * googleAccount = (OTRManagedGoogleAccount *)[OTRManagedAccount accountForAccountType:OTRAccountTypeGoogleTalk];
    googleAccount.username = @"fake.david.chiles@gmail.com";
    [googleAccount setTokenDictionary:GoogleToken];
    
    [self connectAccountAndWait:googleAccount];
    
    [googleAccount MR_deleteEntity];
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveOnlySelfAndWait];
    
    XCTAssertTrue(didConnect,@"Gogole Account Test");
}

- (void)test_FacebookAccount {
    OTRManagedFacebookAccount * facebookAccount = (OTRManagedFacebookAccount *)[OTRManagedAccount accountForAccountType:OTRAccountTypeFacebook];
    facebookAccount.username = @"david@chatsecure.org";
    [facebookAccount setTokenDictionary:FacebookToken];
    
    [self connectAccountAndWait:facebookAccount];
    
    [facebookAccount MR_deleteEntity];
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveOnlySelfAndWait];
    
    XCTAssertTrue(didConnect,@"");
}

- (void)test_XMPPAccounts
{
    
    NSDictionary * accountCredentials = @{@"chatsecure@jabber.me":jabbermePassword,
                                          @"test_chatsecure@jabber.ccc.de":jabberCccPassword,
                                          @"test_chatsecure@jabber.systemli.org":systemliPassword};
    
    [accountCredentials enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        OTRManagedAccount * account = [OTRManagedAccount accountForAccountType:OTRAccountTypeJabber];
        account.username = key;
        account.password = obj;
        
        [self connectAccountAndWait:account];
        
        [account MR_deleteEntity];
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveOnlySelfAndWait];
        
        XCTAssertTrue(didConnect,@"Did Connect XPPP Account: %@",key);
    }];
}

-(void)connectAccountAndWait:(OTRManagedAccount *)account
{
    id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
    didConnect = NO;
    hasCalledBack = NO;
    [protocol connectWithPassword:account.password];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:30];
    while (!hasCalledBack && [loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    if (didConnect) {
        [protocol disconnect];
    }
}

- (void)protocolLoginFailed:(NSNotification*)notification {
    didConnect = NO;
    hasCalledBack = YES;
}

- (void)protocolLoginSuccess:(NSNotification*)notification {
    didConnect = YES;
    hasCalledBack = YES;
}

@end
