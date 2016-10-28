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
    
    /** Create two user accounts and save each other as buddies */
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
    
    /** 
     Setup up use rwith name and a buddy with name 
     Creates:
     1. A database for the user.
     2. An account and buddy for the suesr.
     3. An OTROMEMOSignalCoordinator to do all the signal functionality.
     */
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
    
    /**
     1. Setup two accounts
     2. Authenticate the stream. Should receive devices for our buddy.
     3. Check that we support OMEMO for that buddy. ✔︎
     */
    func testDeviceSetup() {
        self.setupTwoAccounts(#function)
        self.omemoModule?.xmppStreamDidAuthenticate(nil)
        let buddySupport = self.bobUser!.signalOMEMOCoordinator.buddySupportsOMEMO(self.bobUser!.buddy.uniqueId)
        XCTAssertTrue(buddySupport,"Buddy has OMEMO support")
    }
    
    /**
     1. Setup two accounts
     2. Authenticate the stream. Should receive devices for our buddy.
     3. Send a message to the buddy. This should trigger fetching the buddy's bundle to create a session.
     4. Ensure that encryption went correctly. ✔︎
     5. Ensure that that alice received the message. ✔︎
    */
    func testFetchingBundleSetup() {
        self.setupTwoAccounts(#function)
        self.omemoModule?.xmppStreamDidAuthenticate(nil)
        let expectation = self.expectationWithDescription("Sending Message")
        let messageText = "This is message from Bob to Alice"
        self.bobUser!.signalOMEMOCoordinator.encryptAndSendMessage(messageText, buddyYapKey: self.bobUser!.buddy.uniqueId, messageId: "message1") { (success, error) in
            
            XCTAssertTrue(success,"Able to send message")
            XCTAssertNil(error,"Error Sending \(error)")
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(30, handler: nil)
        
        var messageFound = false
        self.aliceUser?.databaseManager.readOnlyDatabaseConnection.readWithBlock({ (transaction) in
            transaction.enumerateKeysAndObjectsInCollection(OTRMessage.collection(), usingBlock: { (key, object, stop) in
                let message = object as! OTRMessage
                XCTAssertEqual(message.text, messageText)
                messageFound = true
            })
            
            transaction.enumerateKeysAndObjectsInCollection(OTROMEMODevice.collection(), usingBlock: { (key, object, stop) in
                let device = object as! OTROMEMODevice
                XCTAssertNotNil(device.lastSeenDate)
            })
            
        })
        XCTAssertTrue(messageFound,"Found message")
    }
    
    func testRemoveDevice() {
        self.setupTwoAccounts(#function)
        self.omemoModule?.xmppStreamDidAuthenticate(nil)
        let expectation = self.expectationWithDescription("Remove Devices")
        let deviceNumber = NSNumber(int:5)
        
        self.bobUser?.databaseManager.readWriteDatabaseConnection.readWriteWithBlock({ (transaction) in
            let device = OTROMEMODevice(deviceId: deviceNumber, trustLevel: OMEMOTrustLevel.TrustedTofu, parentKey: self.bobUser!.account.uniqueId, parentCollection: OTRAccount.collection(), publicIdentityKeyData: nil, lastSeenDate: nil)
            device.saveWithTransaction(transaction)
        })
        self.bobUser?.signalOMEMOCoordinator.removeDevice([deviceNumber], completion: { (result) in
            XCTAssertTrue(result)
            self.bobUser!.databaseManager.readWriteDatabaseConnection.readWithBlock({ (transaction) in
                let yapKey = OTROMEMODevice.yapKeyWithDeviceId(deviceNumber, parentKey: self.bobUser!.account.uniqueId, parentCollection: OTRAccount.collection())
                let device = OTROMEMODevice.fetchObjectWithUniqueID(yapKey, transaction: transaction)
                XCTAssertNil(device)
            })
            
             expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
        
    }
}
