//
//  OTROMEMOStorageCoordinator.swift
//  ChatSecure
//
//  Created by David Chiles on 9/15/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

/**
 * Storage for XMPP-OMEMO 
 * This class handles storage of devies as it relates to our and our buddies device(s).
 * Create one per XMPP account.
 */
public class OTROMEMOStorageManager {
    let databaseConnection:YapDatabaseConnection
    let accountKey:String
    let accountCollection:String
    
    /**
     Create an OTROMEMOStorageManager.
     
     - parameter accountKey: The yap account key
     - parameter accountCollection: They yap account collection
     - parameter databaseConnection: The yap Datatbase connection to perform all the saves and gets from.
     */
    init(accountKey:String, accountCollection:String, databaseConnection:YapDatabaseConnection) {
        self.accountKey = accountKey
        self.accountCollection = accountCollection
        self.databaseConnection = databaseConnection
    }
    
    /**
     Retrievs all the devices for a given yap key and collection. Could be either for a buddy or an account.
     
     - parameter yapKey: The yap key for the account or buddy
     - parameter yapCollection: The yap collection for the account or buddy
     - parameter transaction: The transaction to use to do the look up with 
     
     - returns: An Array of OTROMEMODevices. If there are no devices the array will be empty.
     */
    internal func getDevicesForParentYapKey(yapKey:String, yapCollection:String, transaction:YapDatabaseReadTransaction) -> [OTROMEMODevice] {
        var deviceArray = [OTROMEMODevice]()
        OTROMEMODevice.enumerateDevicesForParentKey(yapKey, collection: yapCollection, transaction: transaction, usingBlock: { (device, stop) in
            deviceArray.append(device)
        })
        return deviceArray
    }
    
    /**
     Convenience method that uses the class database connection.
     Retrievs all the devices for a given yap key and collection. Could be either for a buddy or an account.
     
     - parameter yapKey: The yap key for the account or buddy
     - parameter yapCollection: The yap collection for the account or buddy
     
     - returns: An Array of OTROMEMODevices. If there are no devices the array will be empty.
     **/
    public func getDevicesForParentYapKey(yapKey:String, yapCollection:String) -> [OTROMEMODevice] {
        var result:[OTROMEMODevice]?
        self.databaseConnection.readWithBlock { (transaction) in
            result = self.getDevicesForParentYapKey(yapKey, yapCollection: yapCollection, transaction: transaction)
        }
        return result ?? [OTROMEMODevice]();
    }
    
    /**
     Uses the class account key and collection to get all devices.
     
     - returns: An Array of OTROMEMODevices. If there are no devices the array will be empty.
     */
    public func getDevicesForOurAccount() -> [OTROMEMODevice] {
        return self.getDevicesForParentYapKey(self.accountKey, yapCollection: self.accountCollection)
    }
    
    /**
     Uses the class account key and collection to get all devices for a given bare JID. Uses the class database connection.
     
     - parameter username: The bare JID for the buddy.
     
     - returns: An Array of OTROMEMODevices. If there are no devices the array will be empty.
     */
    public func getDevicesForBuddy(username:String) -> [OTROMEMODevice] {
        var result:[OTROMEMODevice]?
        self.databaseConnection.readWithBlock { (transaction) in
            let buddy = OTRBuddy.fetchBuddyWithUsername(username, withAccountUniqueId: self.accountKey, transaction: transaction)
            result = self.getDevicesForParentYapKey(buddy.uniqueId, yapCollection: OTRBuddy.collection(), transaction: transaction)
        }
        return result ?? [OTROMEMODevice]();
    }
    
    /**
     Store devices for a yap key/collection
     
     - parameter devices: An array of the device numbers. Should be UInt32.
     - parameter parentYapKey: The yap key to attach the device to
     - parameter parentYapCollection: the yap collection to attach the device to
     - parameter transaction: the database transaction to perform the saves on
     */
    private func storeDevices(devices:[NSNumber], parentYapKey:String, parentYapCollection:String, transaction:YapDatabaseReadWriteTransaction) {
        
        let previouslyStoredDevices = self.getDevicesForParentYapKey(parentYapKey, yapCollection: parentYapCollection, transaction: transaction)
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
                
                let newDevice = OTROMEMODevice(deviceId: deviceId, trustLevel:trustLevel, parentKey: parentYapKey, parentCollection: parentYapCollection, publicIdentityKeyData: nil, lastReceivedMessageDate:nil)
                newDevice?.saveWithTransaction(transaction)
            })
            
        }
    }
    
    /**
     Store devices for this account. These should come from the OMEMO device-list
     
     - parameter devices: An array of the device numbers. Should be UInt32.
     */
    public func storeOurDevices(devices:[NSNumber]) {
        self.databaseConnection.readWriteWithBlock { (transaction) in
            self.storeDevices(devices, parentYapKey: self.accountKey, parentYapCollection: self.accountCollection, transaction: transaction)
        }
    }
    
    /**
     Store devices for a buddy connected to this account. These should come from the OMEMO device-list
     
     - parameter devices: An array of the device numbers. Should be UInt32.
     - parameter buddyUsername: The bare JID for the buddy.
     */
    public func storeBuddyDevices(devices:[NSNumber], buddyUsername:String) {
        self.databaseConnection.readWriteWithBlock { (transaction) in
            //TODO: Create buddy if none
            guard let buddy = OTRBuddy.fetchBuddyWithUsername(buddyUsername, withAccountUniqueId: self.accountKey, transaction: transaction) else {
                return
            }
            self.storeDevices(devices, parentYapKey: buddy.uniqueId, parentYapCollection: OTRBuddy.collection(), transaction: transaction)
        }
    }
}
