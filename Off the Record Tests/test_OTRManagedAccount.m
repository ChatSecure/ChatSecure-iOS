//
//  test_OTRManagedAccount.m
//  Off the Record
//
//  Created by David Chiles on 11/21/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OTRManagedAccount.h"
#import "OTRManagedOscarAccount.h"
#import "OTRManagedXMPPAccount.h"
#import "OTRManagedFacebookAccount.h"
#import "OTRManagedGoogleAccount.h"

@interface test_OTRManagedAccount : XCTestCase

@end

@implementation test_OTRManagedAccount

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)test_CreateAccount;
{
    OTRManagedAccount * account = [OTRManagedAccount accountForAccountType:OTRAccountTypeNone];
    XCTAssertNil(account, @"");
    
    account = [OTRManagedAccount accountForAccountType:OTRAccountTypeAIM];
    XCTAssertTrue([account isKindOfClass:[OTRManagedOscarAccount class]], @"Testing Aim account creation");
    
    account = [OTRManagedAccount accountForAccountType:OTRAccountTypeJabber];
    XCTAssertTrue([account isKindOfClass:[OTRManagedXMPPAccount class]], @"");
    
    account = [OTRManagedAccount accountForAccountType:OTRAccountTypeFacebook];
    XCTAssertTrue([account isKindOfClass:[OTRManagedFacebookAccount class]], @"");
    
    account = [OTRManagedAccount accountForAccountType:OTRAccountTypeGoogleTalk];
    XCTAssertTrue([account isKindOfClass:[OTRManagedGoogleAccount class]], @"");
    
}

@end
