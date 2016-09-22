//
//  OTROMEMOStorageCoordinator.swift
//  ChatSecure
//
//  Created by David Chiles on 9/15/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

public class OTROMEMOStorageManager {
    let databaseConnection:YapDatabaseConnection
    let accountKey:String
    let accountCollection:String
    
    init(accountKey:String, accountCollection:String, databaseConnection:YapDatabaseConnection) {
        self.accountKey = accountKey
        self.accountCollection = accountCollection
        self.databaseConnection = databaseConnection
    }
    
    private func getDevicesForParentYapKey(yapKey:String, yapCollection:String, transaction:YapDatabaseReadTransaction) -> [OTROMEMODevice] {
        return OTROMEMODevice.allDeviceIdsForParentKey(yapKey, collection: yapCollection, transaction: transaction)
    }
    
    public func getDevicesForParentYapKey(yapKey:String, yapCollection:String) -> [OTROMEMODevice] {
        var result:[OTROMEMODevice]?
        self.databaseConnection.readWithBlock { (transaction) in
            result = self.getDevicesForParentYapKey(yapKey, yapCollection: yapCollection, transaction: transaction)
        }
        return result ?? [OTROMEMODevice]();
    }
    
    public func getDevicesForOurAccount() -> [OTROMEMODevice] {
        return self.getDevicesForParentYapKey(self.accountKey, yapCollection: self.accountCollection)
    }
    
    public func getDevicesForBuddy(username:String) -> [OTROMEMODevice] {
        var result:[OTROMEMODevice]?
        self.databaseConnection.readWithBlock { (transaction) in
            let buddy = OTRBuddy.fetchBuddyWithUsername(username, withAccountUniqueId: self.accountKey, transaction: transaction)
            result = self.getDevicesForParentYapKey(buddy.uniqueId, yapCollection: OTRBuddy.collection(), transaction: transaction)
        }
        return result ?? [OTROMEMODevice]();
    }
    
    private func storeDevices(devices:[NSNumber], parentYapKey:String, parentYapCollection:String, transaction:YapDatabaseReadWriteTransaction) {
        
        let previouslyStoredDevices = OTROMEMODevice.allDeviceIdsForParentKey(parentYapKey, collection:parentYapCollection, transaction: transaction)
        let previouslyStoredDevicesIds = previouslyStoredDevices.map({ (device) -> NSNumber in
            return device.deviceId
        })
        let previouslyStoredDevicesIdSet = Set(previouslyStoredDevicesIds)
        let newDeviceSet = Set(devices)
        
        if (devices.count == 0) {
            // Remove all devices
            previouslyStoredDevices.forEach({ (device) in
                device.removeWithTransaction(transaction)
            })
        } else if (previouslyStoredDevicesIdSet != newDeviceSet) {
            //New Devices to be saved and list to be reworked
            let devicesToRemove:Set<NSNumber> = previouslyStoredDevicesIdSet.subtract(newDeviceSet)
            let devicesToAdd:Set<NSNumber> = newDeviceSet.subtract(previouslyStoredDevicesIdSet)
            
            devicesToRemove.forEach({ (deviceId) in
                let deviceKey = OTROMEMODevice.yapKeyWithDeviceId(deviceId, parentKey: parentYapKey, parentCollection: parentYapCollection)
                transaction.removeObjectForKey(deviceKey, inCollection: OTROMEMODevice.collection())
            })
            
            devicesToAdd.forEach({ (deviceId) in
                
                var trustLevel:OMEMODeviceTrustLevel = .TrustLevelUntrustedNew
                if (previouslyStoredDevices.count == 0) {
                    //This is the first time we're seeing a device list for this account/buddy so it should be saved as TOFU
                    trustLevel = .TrustLevelTrustedTofu
                }
                
                let newDevice = OTROMEMODevice(deviceId: deviceId, trustLevel:trustLevel, parentKey: parentYapKey, parentCollection: parentYapCollection)
                newDevice?.saveWithTransaction(transaction)
            })
            
        }
    }
    
    public func storeOurDevices(devices:[NSNumber]) {
        self.databaseConnection.readWriteWithBlock { (transaction) in
            self.storeDevices(devices, parentYapKey: self.accountKey, parentYapCollection: self.accountCollection, transaction: transaction)
        }
    }
    
    public func storeBuddyDevices(devices:[NSNumber], buddyUsername:String) {
        self.databaseConnection.readWriteWithBlock { (transaction) in
            let buddy = OTRBuddy.fetchBuddyWithUsername(buddyUsername, withAccountUniqueId: self.accountKey, transaction: transaction)
            self.storeDevices(devices, parentYapKey: buddy.uniqueId, parentYapCollection: OTRBuddy.collection(), transaction: transaction)
        }
    }
}