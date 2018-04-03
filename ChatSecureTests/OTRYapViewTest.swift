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
    let didReceiveObjectChanges: (_ key:String,_ collection:String) -> Void
    let didReceiveViewChanges: (_ row:[YapDatabaseViewRowChange],_ section:[YapDatabaseViewSectionChange]) -> Void
    
    init(didSetup: @escaping () -> Void, objectChanges: @escaping (_ key:String, _ collection:String) -> Void, viewChanges: @escaping (_ row:[YapDatabaseViewRowChange], _ section:[YapDatabaseViewSectionChange]) -> Void) {
        self.didSetup = didSetup
        self.didReceiveObjectChanges = objectChanges
        self.didReceiveViewChanges = viewChanges
    }
}

extension ViewHandlerTestDelegate: OTRYapViewHandlerDelegateProtocol {
    func didSetupMappings(_ handler: OTRYapViewHandler) {
        self.didSetup()
    }
    
    func didReceiveChanges(_ handler: OTRYapViewHandler, key: String, collection: String) {
        self.didReceiveObjectChanges(key, collection)
    }
    
    func didReceiveChanges(_ handler: OTRYapViewHandler, sectionChanges: [YapDatabaseViewSectionChange], rowChanges: [YapDatabaseViewRowChange]) {
        self.didReceiveViewChanges(rowChanges,sectionChanges)
    }
}

class OTRYapViewTest: XCTestCase {
    
    var databaseManager: OTRDatabaseManager?
    
    override func setUp() {
        super.setUp()
        
        if let databaseDirectory = databaseManager?.databaseDirectory {
            FileManager.default.clearDirectory(databaseDirectory)
        }
    }
        
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        databaseManager = nil
        super.tearDown()
    }
        
    func testViewHandlerUpdate() {
        let setupExpecation = self.expectation(description: "Setup Mappings")
        let viewChangeExpectation = self.expectation(description: "Insert buddy")
    
        let databaseManager = OTRDatabaseManager()
        self.databaseManager = databaseManager
        databaseManager.setupTestDatabase(name: #function)
        let viewHandler = OTRYapViewHandler(databaseConnection: databaseManager.longLivedReadOnlyConnection!, databaseChangeNotificationName: DatabaseNotificationName.LongLivedTransactionChanges)
        //For this test we'll look at the buddy view
        viewHandler.setup(OTRAllBuddiesDatabaseViewExtensionName, groups: [OTRBuddyGroup])
        let delegate = ViewHandlerTestDelegate(didSetup: {
            setupExpecation.fulfill()
            //Once our view handler is ready we need to make a change to the database that will be reflected in the view.
            self.databaseManager?.writeConnection?.asyncReadWrite({ (transaction) in
                guard let account = OTRXMPPAccount(username: "account@test.com", accountType: .jabber) else {
                    XCTFail()
                    return
                }
                let buddy = OTRXMPPBuddy()!
                buddy.username = "test@test.com"
                buddy.accountUniqueId = account.uniqueId
                buddy.trustLevel = .roster
                account.save(with: transaction)
                buddy.save(with: transaction)
                
            })
        
            }, objectChanges: { (key, collection) in
        
            }) { (rowChanges, sectionChanges) in
                viewChangeExpectation.fulfill()
            }
        viewHandler.delegate = delegate
        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
