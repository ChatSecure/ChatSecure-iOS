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
open class OTROMEMOStorageManager {
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
    open func getDevicesForParentYapKey(_ yapKey:String, yapCollection:String, trustedOnly:Bool) -> [OMEMODevice] {
        var result:[OMEMODevice] = []
        self.databaseConnection.read { (transaction) in
            result = OMEMODevice.allDevices(forParentKey: yapKey, collection: yapCollection, trustedOnly: trustedOnly, transaction: transaction)
        }
        return result
    }
    
    /**
     Uses the class account key and collection to get all devices.
     
     - returns: An Array of OTROMEMODevices. If there are no devices the array will be empty.
     */
    open func getDevicesForOurAccount(trustedOnly:Bool) -> [OMEMODevice] {
        return self.getDevicesForParentYapKey(self.accountKey, yapCollection: self.accountCollection, trustedOnly: trustedOnly)
    }
    
    /**
     Uses the class account key and collection to get all devices for a given bare JID. Uses the class database connection.
     
     - parameter username: The bare JID for the buddy.
     
     - returns: An Array of OTROMEMODevices. If there are no devices the array will be empty.
     */
    open func getDevicesForBuddy(_ username:String, trustedOnly:Bool) -> [OMEMODevice] {
        guard let jid = XMPPJID(string: username) else { return [] }
        var result: [OMEMODevice] = []
        self.databaseConnection.read { (transaction) in
            if let buddy = OTRXMPPBuddy.fetchBuddy(jid: jid, accountUniqueId: self.accountKey, transaction: transaction) {
                result = self.getDevicesForParentYapKey(buddy.uniqueId, yapCollection: OTRXMPPBuddy.collection, trustedOnly: trustedOnly)
            }
        }
        return result
    }
    
    /**
     Store devices for a yap key/collection
     
     - parameter devices: An array of the device numbers. Should be UInt32.
     - parameter parentYapKey: The yap key to attach the device to
     - parameter parentYapCollection: the yap collection to attach the device to
     - parameter transaction: the database transaction to perform the saves on
     */
    fileprivate func storeDevices(_ devices:[NSNumber], parentYapKey:String, parentYapCollection:String, transaction:YapDatabaseReadWriteTransaction) {
        
        let previouslyStoredDevices = OMEMODevice.allDevices(forParentKey: parentYapKey, collection: parentYapCollection, transaction: transaction)
        let previouslyStoredDevicesIds = previouslyStoredDevices.map({ (device) -> NSNumber in
            return device.deviceId
        })
        let previouslyStoredDevicesIdSet = Set(previouslyStoredDevicesIds)
        let newDeviceSet = Set(devices)
        
        if (devices.count == 0) {
            // Remove all devices
            previouslyStoredDevices.forEach({ (device) in
                device.remove(with: transaction)
            })
        } else if (previouslyStoredDevicesIdSet != newDeviceSet) {
            //New Devices to be saved and list to be reworked
            let devicesToRemove:Set<NSNumber> = previouslyStoredDevicesIdSet.subtracting(newDeviceSet)
            let devicesToAdd:Set<NSNumber> = newDeviceSet.subtracting(previouslyStoredDevicesIdSet)
            
            // Instead of fulling removing devices, mark them as removed for historical purposes
            devicesToRemove.forEach({ (deviceId) in
                let deviceKey = OMEMODevice.yapKey(withDeviceId: deviceId, parentKey: parentYapKey, parentCollection: parentYapCollection)
                guard var device = transaction.object(forKey: deviceKey, inCollection: OMEMODevice.collection) as? OMEMODevice else {
                    return
                }
                device = device.copy() as! OMEMODevice
                device.trustLevel = .removed
                transaction.setObject(device, forKey: device.uniqueId, inCollection: OMEMODevice.collection)
            })
            
            devicesToAdd.forEach({ (deviceId) in
                
                var trustLevel = OMEMOTrustLevel.untrustedNew
                if (previouslyStoredDevices.count == 0) {
                    //This is the first time we're seeing a device list for this account/buddy so it should be saved as TOFU
                    trustLevel = .trustedTofu
                }
                
                let newDevice = OMEMODevice(deviceId: deviceId, trustLevel:trustLevel, parentKey: parentYapKey, parentCollection: parentYapCollection, publicIdentityKeyData: nil, lastSeenDate:Date())
                newDevice.save(with: transaction)
            })
            
        }
    }
    
    /**
     Store devices for this account. These should come from the OMEMO device-list
     
     - parameter devices: An array of the device numbers. Should be UInt32.
     */
    open func storeOurDevices(_ devices:[NSNumber]) {
        self.databaseConnection.asyncReadWrite { (transaction) in
            self.storeDevices(devices, parentYapKey: self.accountKey, parentYapCollection: self.accountCollection, transaction: transaction)
        }
    }
    
    /**
     Store devices for a buddy connected to this account. These should come from the OMEMO device-list
     
     - parameter devices: An array of the device numbers. Should be UInt32.
     - parameter buddyUsername: The bare JID for the buddy.
     */
    open func storeBuddyDevices(_ devices:[NSNumber], buddyUsername:String, completion:(()->Void)?) {
        self.databaseConnection.asyncReadWrite { (transaction) in
            // Fetch the buddy from the database.
            guard let jid = XMPPJID(string: buddyUsername), let buddy = OTRXMPPBuddy.fetchBuddy(jid: jid, accountUniqueId: self.accountKey, transaction: transaction) else {
                // If this is teh first launch the buddy will not be in the buddy list becuase the roster comes in after device list from PEP.
                DDLogWarn("Could not find buddy to store devices \(buddyUsername)")
                return
            }
            self.storeDevices(devices, parentYapKey: buddy.uniqueId, parentYapCollection: buddy.threadCollection, transaction: transaction)
            completion?()
        }
    }
}
