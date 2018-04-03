//
//  OTROMEMOStorageTest.swift
//  ChatSecure
//
//  Created by David Chiles on 9/16/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import XCTest
@testable import ChatSecureCore

extension OTROMEMOSignalCoordinator {
    convenience init(accountYapKey: String, connections: DatabaseConnections) throws {
        let databaseConnection = connections.write
        let capsStorage = XMPPCapabilitiesCoreDataStorage(inMemoryStore: ())!
        let caps = XMPPCapabilities(capabilitiesStorage: capsStorage)
        let serverCaps = OTRServerCapabilities(capabilities: caps, dispatchQueue: nil)
        let file = FileTransferManager(connection: databaseConnection, serverCapabilities: serverCaps, sessionConfiguration: URLSessionConfiguration.ephemeral)
        let cardStorage = VCardStorage(connections: connections)
        let vCard = XMPPvCardTempModule(vCardStorage: cardStorage)
        let roomStorage = RoomStorage(connection: databaseConnection, capabilities: caps, fileTransfer: file, vCardModule: vCard, omemoModule: nil)
        let messageStorage = MessageStorage(connection: databaseConnection, capabilities: caps, fileTransfer: file, roomStorage: roomStorage)
        let mam = XMPPMessageArchiveManagement()
        let roomManager = OTRXMPPRoomManager(databaseConnection: databaseConnection, roomStorage: roomStorage, archiving: mam, dispatchQueue: nil)
        try self.init(accountYapKey: accountYapKey, databaseConnection: databaseConnection, messageStorage: messageStorage, roomManager: roomManager)
    }
}

class OTROmemoStorageTest: XCTestCase {
    
    var databaseManager:OTRDatabaseManager?
    var omemoStorage:OTROMEMOStorageManager!
    var signalStorage:OTRSignalStorageManager!
    var signalCoordinator:OTROMEMOSignalCoordinator!
    var accountKey:String!
    var accountCollection:String!
    let initialDevices:[NSNumber] = [1,2,3]
    let secondDeviceNumbers:[NSNumber] = [1,2,4,5]
    
    override func setUp() {
        super.setUp()
        
        if let databaseDirectory = databaseManager?.databaseDirectory {
            FileManager.default.clearDirectory(databaseDirectory)
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /** 
     * This creates teh necessary database and signal managers. Also creates an account which is required for all the above objects
     *
     */
    func setupDatabase(_ name:String) {
        let account = TestXMPPAccount(username: "", accountType: .jabber)!
        self.accountKey = account.uniqueId
        self.accountCollection = OTRXMPPAccount.collection
        
        
        let databaseManager = OTRDatabaseManager()
        self.databaseManager = databaseManager
        self.databaseManager?.setupTestDatabase(name: name)
        self.omemoStorage = OTROMEMOStorageManager(accountKey: accountKey, accountCollection:accountCollection, databaseConnection: databaseManager.writeConnection!)
        
        self.signalStorage = OTRSignalStorageManager(accountKey: accountKey, databaseConnection: databaseManager.writeConnection!, delegate: nil)
        self.signalCoordinator = try! OTROMEMOSignalCoordinator(accountYapKey: accountKey, connections: databaseManager.connections!)
        
        databaseManager.writeConnection?.readWrite( { (transaction) in
            account.save(with: transaction)
        })
    }
    
    /**
     * Store the inital device list.
     * Ensure the correct trust level is set and that it's attached to the correct account.
     */
    func storeInitialDevices() {
        self.omemoStorage.storeOurDevices(self.initialDevices)
        let firstStoredDevices = omemoStorage.getDevicesForOurAccount(trustedOnly: false)
        XCTAssertEqual(firstStoredDevices.count, self.initialDevices.count)
        firstStoredDevices.forEach { (device) in
            XCTAssert(device.trustLevel == .trustedTofu)
            XCTAssertEqual(device.parentKey, self.accountKey)
            XCTAssertEqual(device.parentCollection, self.accountCollection)
        }
        let firstStoredDeviceId = firstStoredDevices.map { (device) -> NSNumber in
            return device.deviceId
        }
        XCTAssertEqual(Set(self.initialDevices), Set(firstStoredDeviceId))
    }
    
    
    /**
     * Store the second device list. This should override the inital device list and remove devie 3 and add device 4 and 5.
     * Checks to make sure the trust level is set correctly.
     */
    func storeSecondDeviceList() {
        //Now simulate getting a new set of devices where one was removed and two were added.
        
        omemoStorage.storeOurDevices(self.secondDeviceNumbers)
        let secondStoredDevices = omemoStorage.getDevicesForOurAccount(trustedOnly: false)
        XCTAssertEqual(secondStoredDevices.count, 5)
        secondStoredDevices.forEach { (device) in
            
            XCTAssertEqual(device.parentKey, accountKey)
            XCTAssertEqual(device.parentCollection, accountCollection)
            switch device.deviceId {
            case 3:
                XCTAssert(device.trustLevel == .removed)
            case 4:
                fallthrough
            case 5:
                XCTAssert(device.trustLevel == .untrustedNew)
            default:
                XCTAssert(device.trustLevel == .trustedTofu,"Device \(device.deviceId) Should be Tofu")
            }
        }
        let secondStoredDeviceId = secondStoredDevices.map { (device) -> NSNumber in
            return device.deviceId
        }
        XCTAssertEqual(Set([1,2,3,4,5]), Set(secondStoredDeviceId))
    }
    
    func testOmemoFirstDevicesStorage() {
        self.setupDatabase(#function)
        self.storeInitialDevices()
    }
    
    func testOmemoSecondDeviceStorage() {
        self.setupDatabase(#function)
        self.storeInitialDevices()
        self.storeSecondDeviceList()
    }
    
    /**
     * Do the above test and then remove all devices and ensure there are no devices left.
     */
    func testOmemoRemoveDevices() {
        self.setupDatabase(#function)
        self.storeInitialDevices()
        self.storeSecondDeviceList()
        
        let thirdDeviceNumbers = [NSNumber]()
        omemoStorage.storeOurDevices(thirdDeviceNumbers)
        let thirdStoredDevices = omemoStorage.getDevicesForParentYapKey(accountKey, yapCollection: accountCollection, trustedOnly:true)
        XCTAssertEqual(thirdStoredDevices.count, 0)
    }
    
    /**
     * 1. Check to make sure there are no pre-keys currently stored.
     * 2. Add 3 preKeys and check that the current max is correct.
     * 3. Delete a pre-key and check that values are correct
     */
    func testPreKeyStorage() {
        self.setupDatabase(#function)
        
        let none = self.signalStorage.currentMaxPreKeyId()
        XCTAssertNil(none)
        
        //Save a few random prekeys with id.
        //Normally these should be sequential but shouldn't matter
        let keyIds:[UInt32] =  [1,2,100]
        keyIds.forEach { (id) in
            let result = self.signalStorage.storePreKey(Data(), preKeyId: id)
            XCTAssertTrue(result)
        }
        
        XCTAssertEqual(self.signalStorage.currentMaxPreKeyId(),100)
        
        // Delete a prekey. In this case it's the max id but that shouldn't matter either.
        XCTAssertTrue(self.signalStorage.deletePreKey(withId:100))
        XCTAssertFalse(self.signalStorage.containsPreKey(withId:100))
        XCTAssertFalse(self.signalStorage.containsPreKey(withId:999))
        XCTAssertTrue(self.signalStorage.containsPreKey(withId:2))
        
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
    
    /**
     * NOTES: This test is failing because the stored bundle cannot
     * be validated after re-fetching, so it regenerates a completely
     * new bundle. Why does store/fetch corrupt the bundle?
     *
     * 1. Test generating a bundle like on first launch.
     * 2. Remove a few pre keys. This simulates what will happen when the signal library uses up some pre keys from incoming bundle messages
     * 3. Fetch our own bundle again. This time it should all come from the database and the only new information is two new pre-keys to replace teh ones deleted
     */
    func testOurBundleStorage() {
        self.setupDatabase(#function)
        let firstFetch = self.signalCoordinator.fetchMyBundle()!
        XCTAssertNotNil(firstFetch)
        
        var firstPreKeyFetch = [UInt32:Data]()
        firstFetch.preKeys.forEach { (preKey) in
            firstPreKeyFetch.updateValue(preKey.publicKey, forKey: preKey.preKeyId)
        }
        
        //Remove some pre keys
        XCTAssertTrue(self.signalStorage.deletePreKey(withId:22))
        XCTAssertTrue(self.signalStorage.deletePreKey(withId:25))
        
        //Fetch again
        let secondFetch = self.signalCoordinator.fetchMyBundle()!
        XCTAssertNotNil(secondFetch)
        
        var secondPreKeyFetch = [UInt32:Data]()
        secondFetch.preKeys.forEach { (preKey) in
            secondPreKeyFetch.updateValue(preKey.publicKey, forKey: preKey.preKeyId)
        }
        
        XCTAssertEqual(firstFetch.deviceId, secondFetch.deviceId,"Should be the same device id")
        XCTAssertEqual(firstFetch.identityKey, secondFetch.identityKey,"Same Identity Key")
        XCTAssertEqual(firstFetch.signedPreKey.signature, secondFetch.signedPreKey.signature,"Same signature")
        XCTAssertEqual(firstFetch.signedPreKey.preKeyId, secondFetch.signedPreKey.preKeyId,"Same prekey Id")
        XCTAssertEqual(firstFetch.signedPreKey.publicKey, secondFetch.signedPreKey.publicKey,"Same prekey public key")
        //Checking Pre Keys
        
        let firstIdArray = Array(firstPreKeyFetch.keys).sorted()
        let secondIdArray = Array(secondPreKeyFetch.keys).sorted()
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
        XCTAssertNil(self.signalStorage.loadPreKey(withId:22))
        XCTAssertNil(self.signalStorage.loadPreKey(withId:25))
        XCTAssertNotNil(self.signalStorage.loadPreKey(withId:101))
        XCTAssertNotNil(self.signalStorage.loadPreKey(withId:102))
    }
}
