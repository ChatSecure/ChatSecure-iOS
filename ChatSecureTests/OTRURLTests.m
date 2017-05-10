//
//  OTRURLTests.m
//  ChatSecure
//
//  Created by David Chiles on 7/15/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <XCTest/XCTest.h>
@import ChatSecureCore;
@import OTRAssets;
@import XMPPFramework;

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
    XMPPJID *jid = [XMPPJID jidWithString:username];
    NSString *baseUrlString = @"https://chatsecure.org/i/#";
    NSURL *baseURL = [NSURL URLWithString:baseUrlString];
    NSString *fingerprint = @"fingerprint";
    NSString *typeString = [OTRAccount fingerprintStringTypeForFingerprintType:OTRFingerprintTypeOTR];
    NSDictionary <NSString*,NSString*>*fingerprintDictionary = @{typeString:fingerprint};
    
    NSMutableArray<NSURLQueryItem*> *queryItems = [NSMutableArray arrayWithCapacity:fingerprintDictionary.count];
    [fingerprintDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:key value:obj];
        [queryItems addObject:item];
    }];
    // migration = true
    NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:@"m" value:@"1"];
    [queryItems addObject:item];
    
    NSURL *base64URL = [NSURL otr_shareLink:baseURL jid:jid queryItems:queryItems];
    NSURL *base64URLWithoutFingerprint = [NSURL otr_shareLink:baseURL jid:jid queryItems:nil];
    
    void (^block)(XMPPJID * _Nullable inJid, NSArray<NSURLQueryItem*> * _Nullable queryItems) = ^void(XMPPJID * _Nullable inJid, NSArray<NSURLQueryItem*> * _Nullable queryItems) {
        __block NSString *fPrint = nil;
        NSString *otr = [OTRAccount fingerprintStringTypeForFingerprintType:OTRFingerprintTypeOTR];
        [queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name isEqualToString:otr]) {
                fPrint = obj.value;
                *stop = YES;
            }
        }];
        XCTAssertEqualObjects(jid, inJid, @"Username does not match");
        XCTAssertEqualObjects(fingerprint, fPrint, @"Fingerprint does not match");
    };
    
    void (^withoutFingerprintBlock)(XMPPJID * _Nullable inJid, NSArray<NSURLQueryItem*> * _Nullable queryItems) = ^void(XMPPJID * _Nullable inJid, NSArray<NSURLQueryItem*> * _Nullable queryItems) {
        XCTAssertEqualObjects(jid, inJid, @"Username does not match");
    };
    
    [base64URL otr_decodeShareLink:block];
    [base64URLWithoutFingerprint otr_decodeShareLink:withoutFingerprintBlock];
}

@end
