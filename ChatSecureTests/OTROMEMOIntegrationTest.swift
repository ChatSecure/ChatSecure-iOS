//
//  OTROMEMOStreamTest.swift
//  ChatSecure
//
//  Created by David Chiles on 10/6/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import XCTest
import ChatSecureCore

struct TestUser {
    var account:OTRXMPPAccount
    var buddy:OTRBuddy
    var databaseManager:OTRDatabaseManager
    var signalOMEMOCoordinator:OTROMEMOSignalCoordinator
}

class OTROMEMOIntegrationTest: XCTestCase {
    
    // This is teh 'remote' user in this setup
    var aliceUser:TestUser?
    // This is the 'local' user
    var bobUser:TestUser?
    var omemoModule:OTROMEMOTestModule?
    
    override func setUp() {
        super.setUp()
        
        NSFileManager.defaultManager().clearDirectory(OTRTestDatabaseManager.yapDatabaseDirectory())
    }
    
    /** Create two user accounts and save each other as buddies*/
    func setupTwoAccounts(name:String) {
        let aliceName = "\(name)-alice"
        let bobName = "\(name)-bob"
        self.aliceUser = self.setupUserWithName(aliceName,buddyName: bobName)
        self.bobUser = self.setupUserWithName(bobName,buddyName: aliceName)
        self.omemoModule = OTROMEMOTestModule(OMEMOStorage: self.bobUser!.signalOMEMOCoordinator, xmlNamespace: .ConversationsLegacy, dispatchQueue: nil)
        self.omemoModule?.addDelegate(self.bobUser!.signalOMEMOCoordinator, delegateQueue: self.bobUser!.signalOMEMOCoordinator.workQueue)
        self.omemoModule?.otherUser = aliceUser
        self.omemoModule?.thisUser = bobUser
    }
    
    func setupUserWithName(name:String, buddyName:String) -> TestUser {
        let databaseManager = OTRTestDatabaseManager.setupDatabaseWithName(name)
        let account = TestXMPPAccount()
        account.username = "\(name)@fake.com"
        
        let buddy = OTRBuddy()
        buddy.username = "\(buddyName)@fake.com"
        buddy.accountUniqueId = account.uniqueId
        
        databaseManager.readWriteDatabaseConnection.readWriteWithBlock { (transaction) in
            account.saveWithTransaction(transaction)
            buddy.saveWithTransaction(transaction)
        }
        let signalOMEMOCoordinator = try! OTROMEMOSignalCoordinator(accountYapKey: account.uniqueId, databaseConnection: databaseManager.readWriteDatabaseConnection)
        return TestUser(account: account,buddy:buddy, databaseManager: databaseManager, signalOMEMOCoordinator: signalOMEMOCoordinator)
    }
    
    func testBundleSetup() {
        self.setupTwoAccounts(#function)
        self.omemoModule?.xmppStreamDidAuthenticate(nil)
        let buddySupport = self.bobUser!.signalOMEMOCoordinator.buddySupportsOMEMO(self.bobUser!.buddy.uniqueId)
        XCTAssertTrue(buddySupport,"Buddy has OMEMO support")
        
        
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
