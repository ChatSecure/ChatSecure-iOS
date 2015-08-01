//
//  OTRURLTests.m
//  ChatSecure
//
//  Created by David Chiles on 7/15/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSURL+ChatSecure.h"

@interface OTRURLTests : XCTestCase

@end

@implementation OTRURLTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/** Test creating share links and being able to decode sharing links base on https://dev.guardianproject.info/projects/gibberbot/wiki/Invite_Links*/
- (void)testCreatingURL {
    
    NSString *username = @"account@server.com";
    NSString *baseUrl = @"https://chatsecure.org/i/#";
    NSString *fingerprint = @"fingerprint";
    
    NSURL *url = [NSURL otr_shareLink:baseUrl username:username fingerprint:fingerprint base64Encoded:NO];
    NSURL *urlWithOutFingerprint = [NSURL otr_shareLink:baseUrl username:username fingerprint:nil base64Encoded:NO];
    NSURL *base64URL = [NSURL otr_shareLink:baseUrl username:username fingerprint:fingerprint base64Encoded:YES];
    NSURL *base64URLWithoutFingerprint = [NSURL otr_shareLink:baseUrl username:username fingerprint:nil base64Encoded:YES];
    
    void (^block)(NSString *, NSString *) = ^void(NSString *uName, NSString *fPrint) {
        BOOL equalUsername = [username isEqualToString:uName];
        BOOL equalFingerprint = [fingerprint isEqualToString:fPrint];
        XCTAssertTrue(equalUsername,@"Username does not match");
        XCTAssertTrue(equalFingerprint,@"Fingerprint does not match");
    };
    
    void (^withoutFingerprintblock)(NSString *, NSString *) = ^void(NSString *uName, NSString *fPrint) {
        BOOL equalUsername = [username isEqualToString:uName];
        XCTAssertTrue(equalUsername,@"Username does not match");
    };
    
    [base64URL otr_decodeShareLink:block];
    [base64URLWithoutFingerprint otr_decodeShareLink:withoutFingerprintblock];
    [url otr_decodeShareLink:block];
    [urlWithOutFingerprint otr_decodeShareLink:withoutFingerprintblock];
}

@end
