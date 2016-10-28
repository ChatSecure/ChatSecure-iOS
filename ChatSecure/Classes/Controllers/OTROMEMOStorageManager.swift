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
     Convenience method that uses the class database connection.
     Retrievs all the devices for a given yap key and collection. Could be either for a buddy or an account.
     
     - parameter yapKey: The yap key for the account or buddy
     - parameter yapCollection: The yap collection for the account or buddy
     
     - returns: An Array of OTROMEMODevices. If there are no devices the array will be empty.
     **/
    public func getDevicesForParentYapKey(yapKey:String, yapCollection:String, trusted:Bool?) -> [OTROMEMODevice] {
        var result:[OTROMEMODevice]?
        self.databaseConnection.readWithBlock { (transaction) in
            if let trust = trusted {
                result = OTROMEMODevice.allDevicesForParentKey(yapKey, collection: yapCollection, trusted: trust, transaction: transaction)
            } else {
                result = OTROMEMODevice.allDevicesForParentKey(yapKey, collection: yapCollection, transaction: transaction)
            }
        }
        return result ?? [OTROMEMODevice]();
    }
    
    /**
     Uses the class account key and collection to get all devices.
     
     - returns: An Array of OTROMEMODevices. If there are no devices the array will be empty.
     */
    public func getDevicesForOurAccount(trusted:Bool?) -> [OTROMEMODevice] {
        return self.getDevicesForParentYapKey(self.accountKey, yapCollection: self.accountCollection, trusted: trusted)
    }
    
    /**
     Uses the class account key and collection to get all devices for a given bare JID. Uses the class database connection.
     
     - parameter username: The bare JID for the buddy.
     
     - returns: An Array of OTROMEMODevices. If there are no devices the array will be empty.
     */
    public func getDevicesForBuddy(username:String, trusted:Bool?) -> [OTROMEMODevice] {
        var result:[OTROMEMODevice]?
        self.databaseConnection.readWithBlock { (transaction) in
            if let buddy = OTRBuddy.fetchBuddyWithUsername(username, withAccountUniqueId: self.accountKey, transaction: transaction) {
                if let trust = trusted {
                    result = OTROMEMODevice.allDevicesForParentKey(buddy.uniqueId, collection: OTRBuddy.collection(), trusted: trust, transaction: transaction)
                } else {
                    result = OTROMEMODevice.allDevicesForParentKey(buddy.uniqueId, collection: OTRBuddy.collection(), transaction: transaction)
                }
            }
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
        
        let previouslyStoredDevices = OTROMEMODevice.allDevicesForParentKey(parentYapKey, collection: parentYapCollection, transaction: transaction)
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
            
            // Instead of fulling removing devices, mark them as removed for historical purposes
            // TODO - add way to let user remove devices manually
            devicesToRemove.forEach({ (deviceId) in
                let deviceKey = OTROMEMODevice.yapKeyWithDeviceId(deviceId, parentKey: parentYapKey, parentCollection: parentYapCollection)
                guard var device = transaction.objectForKey(deviceKey, inCollection: OTROMEMODevice.collection()) as? OTROMEMODevice else {
                    return
                }
                device = device.copy() as! OTROMEMODevice
                device.trustLevel = .Removed
                transaction.setObject(device, forKey: device.uniqueId, inCollection: OTROMEMODevice.collection())
            })
            
            devicesToAdd.forEach({ (deviceId) in
                
                var trustLevel = OMEMOTrustLevel.UntrustedNew
                if (previouslyStoredDevices.count == 0) {
                    //This is the first time we're seeing a device list for this account/buddy so it should be saved as TOFU
                    trustLevel = .TrustedTofu
                }
                
                let newDevice = OTROMEMODevice(deviceId: deviceId, trustLevel:trustLevel, parentKey: parentYapKey, parentCollection: parentYapCollection, publicIdentityKeyData: nil, lastSeenDate:NSDate())
                newDevice.saveWithTransaction(transaction)
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
            // Fetch the buddy from the database.
            var buddy = OTRBuddy.fetchBuddyWithUsername(buddyUsername, withAccountUniqueId: self.accountKey, transaction: transaction)
            // If this is teh first launch the buddy will not be in the buddy list becuase the roster comes in after device list from PEP.
            // So we create a buddy witht the minimial information we have in order to save the device list.
            if (buddy == nil) {
                buddy = OTRXMPPBuddy()
                buddy?.username = buddyUsername
                buddy?.accountUniqueId = self.accountKey
                buddy?.saveWithTransaction(transaction)
            }
            if let bud = buddy {
                self.storeDevices(devices, parentYapKey: bud.uniqueId, parentYapCollection: OTRBuddy.collection(), transaction: transaction)
            }
            
        }
    }
}
