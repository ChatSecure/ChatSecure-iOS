//
//  OTRYapViewTest.swift
//  ChatSecure
//
//  Created by David Chiles on 2/23/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import XCTest
import ChatSecureCore

class ViewHandlerTestDelegate:NSObject {
    let didSetup: () -> Void
    let didReceiveObjectChanges: (key:String,collection:String) -> Void
    let didReceiveViewChanges: (row:[YapDatabaseViewRowChange],section:[YapDatabaseViewSectionChange]) -> Void
    
    init(didSetup: () -> Void, objectChanges: (key:String, collection:String) -> Void, viewChanges: (row:[YapDatabaseViewRowChange], section:[YapDatabaseViewSectionChange]) -> Void) {
        self.didSetup = didSetup
        self.didReceiveObjectChanges = objectChanges
        self.didReceiveViewChanges = viewChanges
    }
}

extension ViewHandlerTestDelegate: OTRYapViewHandlerDelegateProtocol {
    func didSetupMappings(handler: OTRYapViewHandler) {
        self.didSetup()
    }
    
    func didReceiveChanges(handler: OTRYapViewHandler, key: String, collection: String) {
        self.didReceiveObjectChanges(key: key, collection: collection)
    }
    
    func didReceiveChanges(handler: OTRYapViewHandler, sectionChanges: [YapDatabaseViewSectionChange], rowChanges: [YapDatabaseViewRowChange]) {
        self.didReceiveViewChanges(row: rowChanges,section: sectionChanges)
    }
}

class OTRYapViewTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        
        NSFileManager.defaultManager().clearDirectory(OTRTestDatabaseManager.yapDatabaseDirectory())
        }
        
        override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        }
        
        func testViewHandlerUpdate() {
            let setupExpecation = self.expectationWithDescription("Setup Mappings")
            let viewChangeExpectation = self.expectationWithDescription("Insert buddy")
        
        let databaseManager = OTRTestDatabaseManager.setupDatabaseWithName(#function)
        let viewHandler = OTRYapViewHandler(databaseConnection: databaseManager.longLivedReadOnlyConnection!, databaseChangeNotificationName: DatabaseNotificationName.LongLivedTransactionChanges)
        //For this test we'll look at the buddy view
        viewHandler.setup(OTRAllBuddiesDatabaseViewExtensionName, groups: [OTRBuddyGroup])
        let delegate = ViewHandlerTestDelegate(didSetup: {
            setupExpecation.fulfill()
            //Once our view handler is ready we need to make a change to the database that will be reflected in the view.
            databaseManager.readWriteDatabaseConnection?.asyncReadWriteWithBlock({ (transaction) in
                let buddy = OTRBuddy()!
                let account = OTRAccount()!
                buddy.username = "test@test.com"
                buddy.accountUniqueId = account.uniqueId
                account.saveWithTransaction(transaction)
                buddy.saveWithTransaction(transaction)
                
            })
        
            }, objectChanges: { (key, collection) in
        
            }) { (rowChanges, sectionChanges) in
                viewChangeExpectation.fulfill()
            }
        viewHandler.delegate = delegate
        
        
        
        self.waitForExpectationsWithTimeout(300, handler: nil)
        }
}
