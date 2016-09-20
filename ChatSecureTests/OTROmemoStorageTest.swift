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
                try NSFileManager().removeItemAtPath(path)
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
        self.setupDatabase("test1")
        self.storeInitialDevices()
    }
    
    func testOmemoSecondDeviesStorage() {
        self.setupDatabase("test2")
        self.storeInitialDevices()
        self.storeSecondDeviceList()
    }
    
    func testOmemoRemoveDevices() {
        self.setupDatabase("test3")
        self.storeInitialDevices()
        self.storeSecondDeviceList()
        
        let thirdDeviceNumbers = [NSNumber]()
        omemoStorage.storeOurDevices(thirdDeviceNumbers)
        let thirdStoredDevices = omemoStorage.getDevicesForParentYapKey(accountKey, yapCollection: accountCollection)
        XCTAssertEqual(thirdStoredDevices.count, 0)
    }
    
}
