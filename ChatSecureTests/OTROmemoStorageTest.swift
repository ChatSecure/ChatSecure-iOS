//
//  OTROMEMOStorageTest.swift
//  ChatSecure
//
//  Created by David Chiles on 9/16/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import XCTest
@testable import ChatSecureCore

class OTROmemoStorageTest: XCTestCase {
    
    var databaseManager:OTRDatabaseManager!
    var omemoStorage:OTROMEMOStorageManager!
    var signalStorage:OTRSignalStorageManager!
    var accountKey:String!
    var accountCollection:String!
    let initialDevices:[NSNumber] = [1,2,3]
    let secondDeviceNumbers:[NSNumber] = [1,2,4,5]
    
    override func setUp() {
        super.setUp()
        
        let databaseDirectory = OTRTestDatabaseManager.yapDatabaseDirectory()
        do {
            let contents = try NSFileManager().contentsOfDirectoryAtPath(databaseDirectory)
            try contents.forEach { (path) in
                let fullPath = (databaseDirectory as NSString).stringByAppendingPathComponent(path)
                try NSFileManager().removeItemAtPath(fullPath)
            }
        } catch {
            
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func setupDatabase(name:String) {
        let account = TestXMPPAccount()
        self.accountKey = account.uniqueId
        self.accountCollection = OTRXMPPAccount.collection()
        
        
        self.databaseManager = OTRTestDatabaseManager()
        self.databaseManager.setDatabasePassphrase("help", remember: false, error: nil)
        self.databaseManager.setupDatabaseWithName(name, withMediaStorage: false)
        self.omemoStorage = OTROMEMOStorageManager(accountKey: accountKey, accountCollection:accountCollection, databaseConnection: databaseManager.readWriteDatabaseConnection)
        self.signalStorage = OTRSignalStorageManager(accountKey: accountKey, databaseConnection: databaseManager.readWriteDatabaseConnection, delegate: nil)
        
        databaseManager.readWriteDatabaseConnection.readWriteWithBlock { (transaction) in
            account.saveWithTransaction(transaction)
        }
    }
    
    func storeInitialDevices() {
        self.omemoStorage.storeOurDevices(self.initialDevices)
        let firstStoredDevices = omemoStorage.getDevicesForOurAccount()
        XCTAssertEqual(firstStoredDevices.count, 3)
        firstStoredDevices.forEach { (device) in
            XCTAssertEqual(device.trustLevel, OMEMODeviceTrustLevel.TrustLevelTrustedTofu)
            XCTAssertEqual(device.parentKey, self.accountKey)
            XCTAssertEqual(device.parentCollection, self.accountCollection)
        }
        let firstStoredDeviceId = firstStoredDevices.map { (device) -> NSNumber in
            return device.deviceId
        }
        let difference = Set(self.initialDevices).subtract(Set(firstStoredDeviceId))
        XCTAssertEqual(difference.count, 0)
    }
    
    func storeSecondDeviceList() {
        //Now simulate getting a new set of devices where one was removed and two were added.
        
        omemoStorage.storeOurDevices(self.secondDeviceNumbers)
        let secondStoredDevices = omemoStorage.getDevicesForOurAccount()
        XCTAssertEqual(secondStoredDevices.count, 4)
        secondStoredDevices.forEach { (device) in
            
            XCTAssertEqual(device.parentKey, accountKey)
            XCTAssertEqual(device.parentCollection, accountCollection)
            switch device.deviceId {
            case 4:
                fallthrough
            case 5:
                XCTAssertEqual(device.trustLevel, OMEMODeviceTrustLevel.TrustLevelUntrustedNew)
            default:
                XCTAssertEqual(device.trustLevel, OMEMODeviceTrustLevel.TrustLevelTrustedTofu)
            }
        }
        let secondStoredDeviceId = secondStoredDevices.map { (device) -> NSNumber in
            return device.deviceId
        }
        let secondDifference = Set(secondDeviceNumbers).subtract(Set(secondStoredDeviceId))
        XCTAssertEqual(secondDifference.count, 0)
    }
    
    func testOmemoFirstDevicesStorage() {
        self.setupDatabase(#function)
        self.storeInitialDevices()
    }
    
    func testOmemoSecondDeviesStorage() {
        self.setupDatabase(#function)
        self.storeInitialDevices()
        self.storeSecondDeviceList()
    }
    
    func testOmemoRemoveDevices() {
        self.setupDatabase(#function)
        self.storeInitialDevices()
        self.storeSecondDeviceList()
        
        let thirdDeviceNumbers = [NSNumber]()
        omemoStorage.storeOurDevices(thirdDeviceNumbers)
        let thirdStoredDevices = omemoStorage.getDevicesForParentYapKey(accountKey, yapCollection: accountCollection)
        XCTAssertEqual(thirdStoredDevices.count, 0)
    }
    
    func testPreKeyStorage() {
        self.setupDatabase(#function)
        
        let none = self.signalStorage.currentMaxPreKeyId()
        XCTAssertNil(none)
        
        //Save a few random prekeys with id.
        //Normally these should be sequential but shouldn't matter
        let keyIds:[UInt32] =  [1,2,100]
        keyIds.forEach { (id) in
            self.signalStorage.storePreKey(NSData(), preKeyId: id)
        }
        
        // Delete a prekey. In this case it's the max id but that shouldn't matter either.
        self.signalStorage.deletePreKeyWithId(100)
        XCTAssertFalse(self.signalStorage.containsPreKeyWithId(100))
        XCTAssertFalse(self.signalStorage.containsPreKeyWithId(999))
        XCTAssertTrue(self.signalStorage.containsPreKeyWithId(2))
        
        let result = self.signalStorage.currentMaxPreKeyId()!
        XCTAssertEqual(result, 100)
        
        //Fetch all the remaining prekeys should get back 1,2
        let allRemainingPrekeys = self.signalStorage.fetchAllPreKeys(false)
        let remainingPreKeyIds = allRemainingPrekeys.map { (prekey) -> UInt32 in
            return prekey.keyId
        }
        //Check that it has the two id expected and not the one that was deleted
        XCTAssertTrue(remainingPreKeyIds.contains(1))
        XCTAssertTrue(remainingPreKeyIds.contains(2))
        XCTAssertFalse(remainingPreKeyIds.contains(100))
        XCTAssertEqual(allRemainingPrekeys.count, 2)
    }
    
}
