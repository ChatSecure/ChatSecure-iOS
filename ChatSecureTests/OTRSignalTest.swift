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
        
        // to prevent tests from failing we still need to setup singleton
        // OTRDatabaseManager.shared.setupTestDatabase(name: "tmp")
    }
    
    
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSetupSignal() {
        let ourDatabaseManager = OTRDatabaseManager()
        ourDatabaseManager.setupTestDatabase(name: #function)
        let otherDatbaseManager = OTRDatabaseManager()
        otherDatbaseManager.setupTestDatabase(name: "\(#function)-other")
        
        let ourAccount = TestXMPPAccount(username: "our.account@something.com", accountType: .jabber)!
        let otherAccount = TestXMPPAccount(username: "other.account@something.com", accountType: .jabber)!
        
        let ourDatabaseConnection = ourDatabaseManager.database!.newConnection()
        let otherDatabaseConnection = otherDatbaseManager.database!.newConnection()
        
        ourDatabaseConnection.readWrite({ (transaction) in
            ourAccount.save(with:transaction)
        })
        otherDatabaseConnection.readWrite( { (transaction) in
            otherAccount.save(with:transaction)
        })
        
        let ourEncryptionManager = try! OTRAccountSignalEncryptionManager(accountKey: ourAccount.uniqueId, databaseConnection: ourDatabaseConnection)
        let ourOutgoingBundle = try! ourEncryptionManager.generateOutgoingBundle(10)
        
        let otherEncryptionManager = try! OTRAccountSignalEncryptionManager(accountKey: otherAccount.uniqueId, databaseConnection: otherDatabaseConnection)
        
        otherDatabaseConnection.readWrite( { (transaction) in
            let refetch = otherAccount.refetch(with: transaction)
            XCTAssertNotNil(refetch)
            let buddy = OTRXMPPBuddy()!
            buddy.accountUniqueId = otherAccount.uniqueId
            buddy.username = ourAccount.username
            buddy.save(with:transaction)
            
            let device = OMEMODevice(deviceId: NSNumber(value:ourOutgoingBundle.deviceId), trustLevel: .trustedTofu, parentKey: buddy.uniqueId, parentCollection: OTRXMPPBuddy.collection, publicIdentityKeyData: nil, lastSeenDate:nil)
            device.save(with:transaction)
        })
        ourDatabaseConnection.readWrite ({ (transaction) in
            let refetch = ourAccount.refetch(with: transaction)
            XCTAssertNotNil(refetch)
            let buddy = OTRXMPPBuddy()!
            buddy.accountUniqueId = ourAccount.uniqueId
            buddy.username = otherAccount.username
            buddy.save(with:transaction)
            
            let device = OMEMODevice(deviceId: NSNumber(value:otherEncryptionManager.registrationId), trustLevel: .trustedTofu, parentKey: buddy.uniqueId, parentCollection: OTRXMPPBuddy.collection, publicIdentityKeyData: nil, lastSeenDate:nil)
            device.save(with:transaction)
        })
        
        XCTAssertNotNil(ourOutgoingBundle,"Created our bundle")
        //At this point int 'real' world we could post or outgoing bundle to OMEMO
        
        // 'Other' device is now able to send messages to 'Our' device
        try! otherEncryptionManager.consumeIncomingBundle(ourAccount.username, bundle: ourOutgoingBundle)
        
        let firstString = "Hi buddy"
        let data = firstString.data(using: String.Encoding.utf8)!
        let encryptedData = try! otherEncryptionManager.encryptToAddress(data, name: ourAccount.username, deviceId: ourOutgoingBundle.deviceId)
        XCTAssertNotNil(encryptedData, "Created encrypted data")
        print("\(encryptedData.data)")
        
        // In the real world this encrypted data would be sent over the wire
        let decryptedData = try! ourEncryptionManager.decryptFromAddress(encryptedData.data, name: otherAccount.username, deviceId: otherEncryptionManager.registrationId)
        let secondString = String(data: decryptedData, encoding: .utf8)
        XCTAssertEqual(firstString, secondString,"Equal Strings")
    
    }
    
}
