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
    var signalCoordinator:OTROMEMOSignalCoordinator!
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
        self.signalCoordinator = OTROMEMOSignalCoordinator(accountYapKey: accountKey, databaseConnection: databaseManager.readWriteDatabaseConnection)
        
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
    
    func testOurBundleStorage() {
        self.setupDatabase(#function)
        let firstFetch = self.signalCoordinator.fetchMyBundle()
        XCTAssertNotNil(firstFetch)
        
        var firstPreKeyFetch = [UInt32:NSData]()
        firstFetch.preKeys.forEach { (preKey) in
            firstPreKeyFetch.updateValue(preKey.publicKey, forKey: preKey.preKeyId)
        }
        
        //Remove some pre keys
        self.signalStorage.deletePreKeyWithId(22)
        self.signalStorage.deletePreKeyWithId(25)
        
        //Fetch again
        let secondFetch = self.signalCoordinator.fetchMyBundle()
        XCTAssertNotNil(secondFetch)
        
        var secondPreKeyFetch = [UInt32:NSData]()
        secondFetch.preKeys.forEach { (preKey) in
            secondPreKeyFetch.updateValue(preKey.publicKey, forKey: preKey.preKeyId)
        }
        
        XCTAssertEqual(firstFetch.deviceId, secondFetch.deviceId,"Should be the same device id")
        XCTAssertEqual(firstFetch.identityKey, secondFetch.identityKey,"Same Identity Key")
        XCTAssertEqual(firstFetch.signedPreKey.signature, secondFetch.signedPreKey.signature,"Same signature")
        XCTAssertEqual(firstFetch.signedPreKey.preKeyId, secondFetch.signedPreKey.preKeyId,"Same prekey Id")
        XCTAssertEqual(firstFetch.signedPreKey.publicKey, secondFetch.signedPreKey.publicKey,"Same prekey public key")
        //Checking Pre Keys
        
        let firstIdArray = Array(firstPreKeyFetch.keys).sort()
        let secondIdArray = Array(secondPreKeyFetch.keys).sort()
        //The two deleted keys should not show up in the second key fetch
        XCTAssertFalse(secondIdArray.contains(22),"Should not contain this key id")
        XCTAssertFalse(secondIdArray.contains(25),"Should not contain this key id")
        // Both times it should fetch 100 keys
        XCTAssertEqual(firstIdArray.count, 100,"Should have fetched 100 keys")
        XCTAssertEqual(secondIdArray.count, 100,"Should have fetched 100 keys")
        XCTAssertEqual(firstIdArray.first!, 1,"Should start with id 1")
        XCTAssertEqual(secondIdArray.first!, 1,"Should start with id 1")
        XCTAssertEqual(firstIdArray.last!, 100,"Should end with id 100")
        XCTAssertEqual(secondIdArray.last!, 102,"Should start with id 1")
        
        //Make sure all the data is the same as previous attempt
        secondPreKeyFetch.forEach { (id,secondData) in
            if let firstData = firstPreKeyFetch[id] {
                XCTAssertEqual(firstData, secondData,"Public key information should be the same")
            } else {
                //These should not be in the first set because they were created after we deleted two keys
                let excluded:Set<UInt32> = Set([101,102])
                XCTAssertTrue(excluded.contains(id))
            }
        }
        
        //Double check to make sure that the key information is there or not there depending on added and removed keys.
        XCTAssertNil(self.signalStorage.loadPreKeyWithId(22))
        XCTAssertNil(self.signalStorage.loadPreKeyWithId(25))
        XCTAssertNotNil(self.signalStorage.loadPreKeyWithId(101))
        XCTAssertNotNil(self.signalStorage.loadPreKeyWithId(102))
    }
}
