//
//  OTRSignalTest.swift
//  ChatSecure
//
//  Created by David Chiles on 8/2/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import XCTest
@testable import ChatSecureCore

class OTRSignalTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func setupDatabaseWithName(name:String) -> OTRDatabaseManager {
        let datatabseManager = OTRDatabaseManager()
        datatabseManager.setDatabasePassphrase("password", remember: false, error: nil)
        datatabseManager.setupDatabaseWithName(name, withMediaStorage: false)
        return datatabseManager
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSetupSignal() {
        let ourDatabaseManager = self.setupDatabaseWithName(#function)
        let otherDatbaseManager = self.setupDatabaseWithName("\(#function)-other")
        
        let ourAccount = TestXMPPAccount()
        ourAccount.username = "ourAccount@something.com"
        let otherAccount = TestXMPPAccount()
        otherAccount.username = "otherAccount@something.com"
        
        let ourDatabaseConnection = ourDatabaseManager.newConnection()
        let otherDatabaseConnection = otherDatbaseManager.newConnection()
        
        ourDatabaseConnection.readWriteWithBlock { (transaction) in
            ourAccount.saveWithTransaction(transaction)
        }
        otherDatabaseConnection.readWriteWithBlock { (transaction) in
            otherAccount.saveWithTransaction(transaction)
        }
        
        let ourEncryptionManager = OTRAccountSignalEncryptionManager(accountKey: ourAccount.uniqueId, databaseConnection: ourDatabaseConnection)
        let ourOutgoingBundle = ourEncryptionManager.generateOutgoingBundle()
        
        let otherEncryptionManager = OTRAccountSignalEncryptionManager(accountKey: otherAccount.uniqueId, databaseConnection: otherDatabaseConnection)
        
        XCTAssertNotNil(ourOutgoingBundle,"Created our bundle")
        //At this point int 'real' world we could post or outgoing bundle to OMEMO
        
        //Convert our outgoing bundle to an incoming bundle
        let preKeyInfo = ourOutgoingBundle!.preKeys.first!
        let incomingBundle = OTROMEMOBundleIncoming(bundle: ourOutgoingBundle!.bundle, preKeyId: preKeyInfo.0, preKeyData: preKeyInfo.1)
        // 'Other' device is now able to send messages to 'Our' device
        otherEncryptionManager.consumeIncomingBundle(ourAccount.username, bundle: incomingBundle)
        
        let firstString = "Hi buddy"
        let data = firstString.dataUsingEncoding(NSUTF8StringEncoding)!
        let encryptedData = try! otherEncryptionManager.encryptToAddress(data, name: ourAccount.username, deviceId: incomingBundle.bundle.deviceId)
        XCTAssertNotNil(encryptedData, "Created encrypted data")
        print("\(encryptedData.data)")
        
        // In the real world this encrypted data would be sent over the wire
        // How does device id get over?
        let decryptedData = try! ourEncryptionManager.decryptFromAddress(encryptedData.data, name: otherAccount.username, deviceId: otherEncryptionManager.registrationId)
        let secondString = NSString(data: decryptedData, encoding: NSUTF8StringEncoding) as! String
        
        XCTAssertEqual(firstString, secondString,"Equal Strings")
    }
    
}
