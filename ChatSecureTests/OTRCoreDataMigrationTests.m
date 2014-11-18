//
//  OTRCoreDataMigrationTests.m
//  ChatSecure
//
//  Created by David Chiles on 11/17/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OTRDatabaseManager.h"
#import "CoreData+MagicalRecord.h"

#import "OTRManagedXMPPAccount.h"
#import "OTRManagedGoogleAccount.h"
#import "OTRManagedFacebookAccount.h"
#import "OTRAccount.h"

@interface OTRCoreDataMigrationTests : XCTestCase

@end

@implementation OTRCoreDataMigrationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testYapDatabaseMigration {
    
    NSString *coreDataStoreName = @"ChatSecure.sqlite";
    NSString *yapDatabaseName = @"test.sqlite";
    NSURL *coreDataURL = [NSPersistentStore MR_urlForStoreName:coreDataStoreName];
    NSString *yapPath = [OTRDatabaseManager yapDatabasePathWithName:yapDatabaseName];;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[coreDataURL path]]) {
        [[NSFileManager defaultManager] removeItemAtURL:coreDataURL error:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:yapPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:yapPath error:nil];
    }
    
    
    
    [MagicalRecord setShouldAutoCreateManagedObjectModel:NO];
    [MagicalRecord setDefaultModelNamed:@"ChatSecure.momd"];
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:coreDataStoreName];
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    
    OTRManagedXMPPAccount *xmppAccount = [OTRManagedXMPPAccount MR_createInContext:context];
    xmppAccount.username = @"test@xmpp.com";
    xmppAccount.domain = @"domain.com";
    
    OTRManagedGoogleAccount *googleAccount = [OTRManagedGoogleAccount MR_createInContext:context];
    googleAccount.username = @"google@gmail.com";
    
    OTRManagedFacebookAccount *facebookAccount = [OTRManagedFacebookAccount MR_createInContext:context];
    facebookAccount.username = @"facebook@facebook.com";
    
    [context save:nil];
    
    
    
    [[OTRDatabaseManager sharedInstance] setupDatabaseWithName:yapDatabaseName];
    
    __block NSUInteger numberOfAccounts = 0;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[OTRAccount collection] usingBlock:^(NSString *key, id object, BOOL *stop) {
            if ([object isKindOfClass:[OTRAccount class]]) {
                numberOfAccounts += 1;
                
            }
        }];
    }];
    
    
    XCTAssert(numberOfAccounts == 3, @"Not enough accounts");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
