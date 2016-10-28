//
//  OTRSignalStorageManager.swift
//  ChatSecure
//
//  Created by David Chiles on 7/21/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import SignalProtocolObjC
import YapDatabase

public protocol OTRSignalStorageManagerDelegate: class {
    /** Generate a new account key*/
    func generateNewIdenityKeyPairForAccountKey(accountKey:String) -> OTRAccountSignalIdentity
}

/**
 * This class implements the SignalStore protocol. One OTRSignalStorageManager should be created per account key/collection.
 */
public class OTRSignalStorageManager: NSObject {
    public let accountKey:String
    public let databaseConnection:YapDatabaseConnection
    public weak var delegate:OTRSignalStorageManagerDelegate?
    
    /**
     Create a Signal Store Manager for each account.
     
     - parameter accountKey: The yap key for the parent account.
     - parameter databaseConnection: The yap connection to use internally
     - parameter delegate: An object that handles OTRSignalStorageManagerDelegate
     */
    public init(accountKey:String, databaseConnection:YapDatabaseConnection, delegate:OTRSignalStorageManagerDelegate?) {
        self.accountKey = accountKey
        self.databaseConnection = databaseConnection
        self.delegate = delegate
    }
    
    /** 
     Convenience function to create a new OTRAccountSignalIdentity and save it to yap
     
     - returns: an OTRAccountSignalIdentity that is already saved to the database
     */
    private func generateNewIdenityKeyPair() -> OTRAccountSignalIdentity {
        // Might be a better way to guarantee we have an OTRAccountSignalIdentity
        let identityKeyPair = (self.delegate?.generateNewIdenityKeyPairForAccountKey(self.accountKey))!
        
        self.databaseConnection.readWriteWithBlock { (transaction) in
            identityKeyPair.saveWithTransaction(transaction)
        }
        
        return identityKeyPair
    }
    
    //MARK: Database Utilities
    
    /**
     Fetches the OTRAccountSignalIdentity for the account key from this class.
     
     returns: An OTRAccountSignalIdentity or nil if none was created and stored.
     */
    private func accountSignalIdentity() -> OTRAccountSignalIdentity? {
        var identityKeyPair:OTRAccountSignalIdentity? = nil
        self.databaseConnection.readWithBlock { (transaction) in
            identityKeyPair = OTRAccountSignalIdentity.fetchObjectWithUniqueID(self.accountKey, transaction: transaction)
        }
        
        return identityKeyPair
    }
    
    private func storePreKey(preKey: NSData, preKeyId: UInt32, transaction:YapDatabaseReadWriteTransaction) -> Bool {
        guard let preKeyDatabaseObject = OTRSignalPreKey(accountKey: self.accountKey, keyId: preKeyId, keyData: preKey) else {
            return false
        }
        preKeyDatabaseObject.saveWithTransaction(transaction)
        return true
    }
    
    /** 
     Save a bunch of pre keys in one database transaction
     
     - parameters preKeys: The array of pre-keys to be stored
     
     - return: Whether the storage was successufl
     */
    public func storeSignalPreKeys(preKeys:[SignalPreKey]) -> Bool {
        
        if preKeys.count == 0 {
            return true
        }
        
        var success = false
        self.databaseConnection.readWriteWithBlock { (transaction) in
            for pKey in preKeys {
                if let data = pKey.serializedData() {
                    success = self.storePreKey(data, preKeyId: pKey.preKeyId(), transaction: transaction)
                } else {
                    success = false
                }
                
                if !success {
                    break
                }
            }
        }
        return success
    }
    
    /**
     Returns the current max pre-key id for this account. This includes both deleted and existing pre-keys. This is fairly quick as it uses a secondary index and
     aggregate function MAX(OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName) WHERE OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName =?, self.accountKey
     
     returns: The current max in the yap database. If there are no pre-keys then returns none.
    */
    internal func currentMaxPreKeyId() ->  UInt32? {
        var maxId:UInt32?
        self.databaseConnection.readWithBlock { (transaction) in
            guard let secondaryIndexTransaction = transaction.ext(DatabaseExtensionName.SecondaryIndexName.name()) as? YapDatabaseSecondaryIndexTransaction else {
                return
            }
            let query = YapDatabaseQuery.init(aggregateFunction: "MAX(\(OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName))", string: "WHERE \(OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName) = ?", parameters: ["\(self.accountKey)"])
            if let result = secondaryIndexTransaction.performAggregateQuery(query) as? NSNumber {
                maxId = result.unsignedIntValue
            }
        }
        return maxId
    }
    
    /**
     Fetch all pre-keys for this class's account. This can include deleted pre-keys which are OTRSignalPreKey witout any keyData.
     
     - parameter includeDeleted: If deleted pre-keys are included in the result
     
     - return: An array of OTRSignalPreKey(s). If ther eare no pre-keys then the array will be empty.
     */
    internal func fetchAllPreKeys(includeDeleted:Bool) -> [OTRSignalPreKey] {
        var preKeys = [OTRSignalPreKey]()
        self.databaseConnection.readWithBlock { (transaction) in
            guard let secondaryIndexTransaction = transaction.ext(DatabaseExtensionName.SecondaryIndexName.name()) as? YapDatabaseSecondaryIndexTransaction else {
                return
            }
            
            let query = YapDatabaseQuery(string: "WHERE (OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName) = ?", parameters:  ["\(self.accountKey)"])
            secondaryIndexTransaction.enumerateKeysAndObjectsMatchingQuery(query, usingBlock: { (collection, key, object, stop) in
                guard let preKey = object as? OTRSignalPreKey else {
                    return
                }
                
                if(preKey.keyData != nil || includeDeleted) {
                    preKeys.append(preKey)
                }
            })
        }
        return preKeys
    }
    
    /**
     This fetches the associated account's bundle from yap. If any piece of the bundle is missing it returns nil.
     
     - return: A complete outgoing bundle.
     */
    public func fetchOurExistingBundle() -> OTROMEMOBundleOutgoing? {
        var simpleBundle:OTROMEMOBundle? = nil
        //Fetch and create the base bundle
        self.databaseConnection.readWithBlock { (transaction) in
            do {
                guard let identityKeyPair = OTRAccountSignalIdentity.fetchObjectWithUniqueID(self.accountKey, transaction: transaction),
                    let signedPreKeyDataObject = OTRSignalSignedPreKey.fetchObjectWithUniqueID(self.accountKey, transaction: transaction) else {
                        return
                }
                let signedPreKey = try SignalSignedPreKey(serializedData: signedPreKeyDataObject.keyData)
                
                let publicIdentityKey = identityKeyPair.identityKeyPair.publicKey
                simpleBundle = OTROMEMOBundle(deviceId: identityKeyPair.registrationId, publicIdentityKey: publicIdentityKey, signedPublicPreKey: signedPreKey.keyPair().publicKey, signedPreKeyId: signedPreKey.preKeyId(), signedPreKeySignature: signedPreKey.signature())
            } catch {
                
            }
        }
        
        guard let bundle = simpleBundle else  {
            return nil
        }
        
        //Gather pieces of outgoing bundle
        let preKeys = self.fetchAllPreKeys(false)
        
        var preKeyDict = [UInt32: NSData]()
        preKeys.forEach({ (preKey) in
            guard let data = preKey.keyData else {
                return
            }
            do {
                let signalPreKey = try SignalPreKey(serializedData: data)
                
                preKeyDict.updateValue(signalPreKey.keyPair().publicKey, forKey: preKey.keyId)
            } catch {
                
            }
        })
        
        return OTROMEMOBundleOutgoing(bundle: bundle, preKeys: preKeyDict)
    }
    
    private func fetchDeviceForSignalAddress(signalAddress:SignalAddress, transaction:YapDatabaseReadTransaction) -> OTROMEMODevice? {
        guard let parentEntry = self.parentKeyAndCollectionForSignalAddress(signalAddress, transaction: transaction) else {
            return nil
        }
        
        let deviceNumber = NSNumber(int: signalAddress.deviceId)
        let deviceYapKey = OTROMEMODevice.yapKeyWithDeviceId(deviceNumber, parentKey: parentEntry.key, parentCollection: parentEntry.collection)
        guard let device = OTROMEMODevice.fetchObjectWithUniqueID(deviceYapKey, transaction: transaction) else {
            return nil
        }
        return device
    }
    
    private func parentKeyAndCollectionForSignalAddress(signalAddress:SignalAddress, transaction:YapDatabaseReadTransaction) -> OTRDatabaseEntry? {
        var parentKey:String? = nil
        var parentCollection:String? = nil
        
        let ourAccount = OTRAccount.fetchObjectWithUniqueID(self.accountKey, transaction: transaction)
        if ourAccount?.username == signalAddress.name {
            
            parentKey = self.accountKey
            parentCollection = OTRAccount.collection()
            
        } else if let buddy = OTRBuddy.fetchBuddyWithUsername(signalAddress.name, withAccountUniqueId: self.accountKey, transaction: transaction) {
            parentKey = buddy.uniqueId
            parentCollection = OTRBuddy.collection()
        }
        
        guard let key = parentKey, let collection = parentCollection else {
            return nil
        }
        
        return OTRDatabaseEntry(key: key, collection: collection)
    }
}
//MARK: SignalStore
extension OTRSignalStorageManager: SignalStore {
    
    //MARK: SignalSessionStore
    public func sessionRecordForAddress(address: SignalAddress) -> NSData? {
        let yapKey = OTRSignalSession.uniqueKeyForAccountKey(self.accountKey, name: address.name, deviceId: address.deviceId)
        var sessionData:NSData? = nil
        self.databaseConnection.readWithBlock { (transaction) in
            sessionData = OTRSignalSession.fetchObjectWithUniqueID(yapKey, transaction: transaction)?.sessionData
        }
        return sessionData
    }
    
    public func storeSessionRecord(recordData: NSData, forAddress address: SignalAddress) -> Bool {
        guard let session = OTRSignalSession(accountKey: self.accountKey, name: address.name, deviceId: address.deviceId, sessionData: recordData) else {
            return false
        }
        self.databaseConnection.readWriteWithBlock { (transaction) in
            session.saveWithTransaction(transaction)
        }
        return true
    }
    
    public func sessionRecordExistsForAddress(address: SignalAddress) -> Bool {
        if let _ = self.sessionRecordForAddress(address) {
            return true
        } else {
            return false
        }
    }
    
    public func deleteSessionRecordForAddress(address: SignalAddress) -> Bool {
        let yapKey = OTRSignalSession.uniqueKeyForAccountKey(self.accountKey, name: address.name, deviceId: address.deviceId)
        self.databaseConnection.readWriteWithBlock { (transaction) in
            transaction.removeObjectForKey(yapKey, inCollection: OTRSignalSession.collection())
        }
        return true
    }
    
    public func allDeviceIdsForAddressName(addressName: String) -> [NSNumber] {
        var addresses = [NSNumber]()
        self.databaseConnection.readWithBlock { (transaction) in
            transaction.enumerateSessions(accountKey: self.accountKey, signalAddressName: addressName, block: { (session, stop) in
                addresses.append(NSNumber(int: session.deviceId))
            })
        }
        return addresses
    }
    
    public func deleteAllSessionsForAddressName(addressName: String) -> Int32 {
        var count:Int32 = 0
        self.databaseConnection.readWriteWithBlock( { (transaction) in
            var sessionKeys = [String]()
            transaction.enumerateSessions(accountKey: self.accountKey, signalAddressName: addressName, block: { (session, stop) in
                sessionKeys.append(session.uniqueId)
            })
            count = Int32(sessionKeys.count)
            for key in sessionKeys {
                transaction.removeObjectForKey(key, inCollection: OTRSignalSession.collection())
            }
        })
        return count
    }
    
    //MARK: SignalPreKeyStore
    public func loadPreKeyWithId(preKeyId: UInt32) -> NSData? {
        var preKeyData:NSData? = nil
        self.databaseConnection.readWithBlock { (transaction) in
            let yapKey = OTRSignalPreKey.uniqueKeyForAccountKey(self.accountKey, keyId: preKeyId)
            if let signedPreKey = OTRSignalPreKey.fetchObjectWithUniqueID(yapKey, transaction: transaction) {
                preKeyData = signedPreKey.keyData
            }
        }
        return preKeyData
    }
    
    public func storePreKey(preKey: NSData, preKeyId: UInt32) -> Bool {
        var result = false
        self.databaseConnection.readWriteWithBlock { (transaction) in
            result = self.storePreKey(preKey, preKeyId: preKeyId, transaction: transaction)
        }
        return result
    }
    
    public func containsPreKeyWithId(preKeyId: UInt32) -> Bool {
        if let _ = self.loadPreKeyWithId(preKeyId) {
            return true
        } else {
            return false
        }
    }
    
    public func deletePreKeyWithId(preKeyId: UInt32) -> Bool {
        self.databaseConnection.readWriteWithBlock { (transaction) in
            let yapKey = OTRSignalPreKey.uniqueKeyForAccountKey(self.accountKey, keyId: preKeyId)
            let preKey = OTRSignalPreKey.fetchObjectWithUniqueID(yapKey, transaction: transaction)
            preKey?.keyData = nil
            preKey?.saveWithTransaction(transaction)
        }
        return true
    }
    
    //MARK: SignalSignedPreKeyStore
    public func loadSignedPreKeyWithId(signedPreKeyId: UInt32) -> NSData? {
        var preKeyData:NSData? = nil
        self.databaseConnection.readWithBlock { (transaction) in
            if let signedPreKey = OTRSignalSignedPreKey.fetchObjectWithUniqueID(self.accountKey, transaction: transaction) {
                preKeyData = signedPreKey.keyData
            }
        }
        
        return preKeyData
    }
    
    public func storeSignedPreKey(signedPreKey: NSData, signedPreKeyId: UInt32) -> Bool {
        guard let signedPreKeyDatabaseObject = OTRSignalSignedPreKey(accountKey: self.accountKey, keyId: signedPreKeyId, keyData: signedPreKey) else {
            return false
        }
        self.databaseConnection.readWriteWithBlock { (transaction) in
            signedPreKeyDatabaseObject.saveWithTransaction(transaction)
        }
        return true
        
    }
    
    public func containsSignedPreKeyWithId(signedPreKeyId: UInt32) -> Bool {
        if let _ = self.loadSignedPreKeyWithId(signedPreKeyId) {
            return true
        } else {
            return false
        }
    }
    
    public func removeSignedPreKeyWithId(signedPreKeyId: UInt32) -> Bool {
        self.databaseConnection.readWriteWithBlock { (transaction) in
            transaction.removeObjectForKey(self.accountKey, inCollection: OTRSignalSignedPreKey.collection())
        }
        return true
    }
    
    //MARK: SignalIdentityKeyStore
    public func getIdentityKeyPair() -> SignalIdentityKeyPair {
        
        if let result = self.accountSignalIdentity() {
            return result.identityKeyPair
        }
        //Generate new identitiy key pair?
        return self.generateNewIdenityKeyPair().identityKeyPair
    }
    
    public func getLocalRegistrationId() -> UInt32 {
        
        if let result = self.accountSignalIdentity() {
            return result.registrationId;
        } else {
            //Generate new registration ID?
            return self.generateNewIdenityKeyPair().registrationId
        }
    }
    
    
    public func saveIdentity(address: SignalAddress, identityKey: NSData?) -> Bool {
        var result = false
        self.databaseConnection.readWriteWithBlock { (transaction) in
            if let device = self.fetchDeviceForSignalAddress(address, transaction: transaction) {
                let newDevice = OTROMEMODevice(deviceId: device.deviceId, trustLevel: device.trustLevel, parentKey: device.parentKey, parentCollection: device.parentCollection, publicIdentityKeyData: identityKey, lastSeenDate:device.lastSeenDate)
                newDevice.saveWithTransaction(transaction)
                result = true
            } else if let parentEntry = self.parentKeyAndCollectionForSignalAddress(address, transaction: transaction) {
                
                //See if we have any devices
                var hasDevices = false
                OTROMEMODevice.enumerateDevicesForParentKey(parentEntry.key, collection: parentEntry.collection, transaction: transaction, usingBlock: { (device, stop) in
                    hasDevices = true
                    stop.memory = true
                })
                
                var trustLevel = OMEMOTrustLevel.UntrustedNew
                if (!hasDevices) {
                    //This is the first time we're seeing a device list for this account/buddy so it should be saved as TOFU
                    trustLevel = .TrustedTofu
                }
                let deviceIdNumber = NSNumber(int: address.deviceId)
                let newDevice = OTROMEMODevice(deviceId: deviceIdNumber, trustLevel: trustLevel, parentKey: parentEntry.key, parentCollection: parentEntry.collection, publicIdentityKeyData: identityKey, lastSeenDate:NSDate())
                newDevice.saveWithTransaction(transaction)
                result = true
            }
        }
        return result
    }
    
    
    // We always return true here because we want Signal to always encrypt and decrypt messages. We deal with trust elsewhere.
    public func isTrustedIdentity(address: SignalAddress, identityKey: NSData) -> Bool {
//        var result = false
//        self.databaseConnection.readWriteWithBlock { (transaction) in
//            guard let device = self.fetchDeviceForSignalAddress(address, transaction: transaction) else {
//                return
//            }
//            
//            // Device has to be previously trusted by user or Tofu
//            if (device.trustLevel == .TrustLevelTrustedTofu || device.trustLevel == .TrustLevelTrustedUser) {
//                
//                // If there is data stored then it needs to be equal otherwise no key stored yet so trust it since first time seing it.
//                if let storedKeyData = device.publicIdentityKeyData {
//                    result = storedKeyData.isEqualToData(identityKey)
//                } else {
//                    result = true
//                }
//            }
//            
//        }
//        return result
        return true
    }
    
    //MARK: SignalSenderKeyStore
    
    public func storeSenderKey(senderKey: NSData, address: SignalAddress, groupId: String) -> Bool {
        self.databaseConnection.readWriteWithBlock { (transaction) in
            guard let senderKey = OTRSignalSenderKey(accountKey: self.accountKey, name: address.name, deviceId: address.deviceId, groupId: groupId, senderKey: senderKey) else {
                return
            }
            senderKey.saveWithTransaction(transaction)
        }
        return true
    }
    
    public func loadSenderKeyForAddress(address: SignalAddress, groupId: String) -> NSData? {
        var senderKeyData:NSData? = nil
        self.databaseConnection.readWithBlock { (transaction) in
            let yapKey = OTRSignalSenderKey.uniqueKeyFromAccountKey(self.accountKey, name: address.name, deviceId: address.deviceId, groupId: groupId)
            let senderKey = OTRSignalSenderKey.fetchObjectWithUniqueID(yapKey, transaction: transaction)
            senderKeyData = senderKey?.senderKey
        }
        return senderKeyData
    }
}
