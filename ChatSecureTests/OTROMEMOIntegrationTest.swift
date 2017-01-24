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
    var aliceOmemoModule:OTROMEMOTestModule?
    // This is the 'local' user
    var bobUser:TestUser?
    var bobOmemoModule:OTROMEMOTestModule?
    
    override func setUp() {
        super.setUp()
        
        NSFileManager.defaultManager().clearDirectory(OTRTestDatabaseManager.yapDatabaseDirectory())
    }
    
    /** Create two user accounts and save each other as buddies */
    func setupTwoAccounts(name:String) {
        let aliceName = "\(name)-alice"
        let bobName = "\(name)-bob"
        self.aliceUser = self.setupUserWithName(aliceName,buddyName: bobName)
        self.aliceOmemoModule = OTROMEMOTestModule(OMEMOStorage: self.aliceUser!.signalOMEMOCoordinator, xmlNamespace: .ConversationsLegacy, dispatchQueue: nil)
        self.aliceOmemoModule?.addDelegate(self.aliceUser!.signalOMEMOCoordinator, delegateQueue: self.aliceUser!.signalOMEMOCoordinator.workQueue)
        self.aliceOmemoModule?.thisUser = aliceUser
        
        self.bobUser = self.setupUserWithName(bobName,buddyName: aliceName)
        self.bobOmemoModule = OTROMEMOTestModule(OMEMOStorage: self.bobUser!.signalOMEMOCoordinator, xmlNamespace: .ConversationsLegacy, dispatchQueue: nil)
        self.bobOmemoModule?.addDelegate(self.bobUser!.signalOMEMOCoordinator, delegateQueue: self.bobUser!.signalOMEMOCoordinator.workQueue)
        self.bobOmemoModule?.thisUser = bobUser
        
        
        self.aliceOmemoModule?.otherUser = self.bobOmemoModule
        self.bobOmemoModule?.otherUser = self.aliceOmemoModule
        
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
        self.bobOmemoModule?.xmppStreamDidAuthenticate(nil)
        let buddy = self.bobUser!.buddy
        let connection = self.bobUser?.databaseManager.readOnlyDatabaseConnection
        connection?.readWithBlock({ (transaction) in
            let devices = OTROMEMODevice.allDevicesForParentKey(buddy.uniqueId, collection: buddy.dynamicType.collection(), transaction: transaction)
            XCTAssert(devices.count > 0)
        })
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
        self.bobOmemoModule?.xmppStreamDidAuthenticate(nil)
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
            transaction.enumerateKeysAndObjectsInCollection(OTRBaseMessage.collection(), usingBlock: { (key, object, stop) in
                if let message = object as? OTRBaseMessage {
                    XCTAssertEqual(message.text, messageText)
                    messageFound = true
                }
                
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
        self.bobOmemoModule?.xmppStreamDidAuthenticate(nil)
        let expectation = self.expectationWithDescription("Remove Devices")
        let deviceNumber = NSNumber(int:5)
        let device = OTROMEMODevice(deviceId: deviceNumber, trustLevel: OMEMOTrustLevel.TrustedTofu, parentKey: self.bobUser!.account.uniqueId, parentCollection: OTRAccount.collection(), publicIdentityKeyData: nil, lastSeenDate: nil)
        
        self.bobUser?.databaseManager.readWriteDatabaseConnection.readWriteWithBlock({ (transaction) in
            
            device.saveWithTransaction(transaction)
        })
        self.bobUser?.signalOMEMOCoordinator.removeDevice([device], completion: { (result) in
            XCTAssertTrue(result)
            self.bobUser!.databaseManager.readOnlyDatabaseConnection.readWithBlock({ (transaction) in
                let yapKey = OTROMEMODevice.yapKeyWithDeviceId(deviceNumber, parentKey: self.bobUser!.account.uniqueId, parentCollection: OTRAccount.collection())
                let device = OTROMEMODevice.fetchObjectWithUniqueID(yapKey, transaction: transaction)
                XCTAssertNil(device)
            })
            
             expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
        
    }
}
