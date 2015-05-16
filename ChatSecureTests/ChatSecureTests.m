//
//  ChatSecureTests.m
//  ChatSecureTests
//
//  Created by David Chiles on 11/14/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "XMPPURI.h"

@interface ChatSecureTests : XCTestCase

@end

@implementation ChatSecureTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testPlainXMPPURIParser {
    NSString *username = @"username";
    NSString *domain = @"example.com";
    XMPPJID *jid1 = [XMPPJID jidWithUser:username domain:domain resource:nil];
    XMPPURI *uri1 = [[XMPPURI alloc] initWithJID:jid1 fingerprint:nil];
    NSString *uriString = uri1.uriString;
    NSURL *url = [NSURL URLWithString:uriString];
    XMPPURI *uri2 = [[XMPPURI alloc] initWithURL:url];
    
    XMPPJID *jid2 = uri2.jid;
    XCTAssertEqualObjects(username, jid2.user);
    XCTAssertEqualObjects(domain, jid2.domain);
}

- (void) testXMPPURIParserWithOTR {
    NSString *uriString = @"xmpp:nathan@guardianproject.info/?otr-fingerprint=C9BC6E902B11C5C100EB017E8E15E0617A9939D3";
    NSURL *url = [NSURL URLWithString:uriString];
    XMPPURI *uri2 = [[XMPPURI alloc] initWithURL:url];
    
    XMPPJID *jid2 = uri2.jid;
}

@end
