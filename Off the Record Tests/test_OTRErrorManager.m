//
//  test_OTRErrorManager.m
//  Off the Record
//
//  Created by David Chiles on 12/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OTRErrorManager.h"

@interface test_OTRErrorManager : XCTestCase

@end

@implementation test_OTRErrorManager

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

- (void) test_errorStringWithSSLStatus {
    
    NSString * noErrorString = [OTRErrorManager errorStringWithSSLStatus:noErr];
    XCTAssertNotNil(noErrorString, @"noErr string");
    for (OSStatus i = errSSLProtocol; i>= errSSLUnexpectedRecord; i--) {
        NSString * errorString = nil;
        errorString = [OTRErrorManager errorStringWithSSLStatus:i];
        XCTAssertNotNil(errorString, @"Checking Error %d",(int)i);
    }
    
}

@end
