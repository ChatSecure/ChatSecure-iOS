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
    func generateNewIdenityKeyPairForAccountKey(_ accountKey:String) -> OTRAccountSignalIdentity
}

/**
 * This class implements the SignalStore protocol. One OTRSignalStorageManager should be created per account key/collection.
 */
open class OTRSignalStorageManager: NSObject {
    open let accountKey:String
    open let databaseConnection:YapDatabaseConnection
    open weak var delegate:OTRSignalStorageManagerDelegate?
    
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
    fileprivate func generateNewIdenityKeyPair() -> OTRAccountSignalIdentity {
        // Might be a better way to guarantee we have an OTRAccountSignalIdentity
        let identityKeyPair = (self.delegate?.generateNewIdenityKeyPairForAccountKey(self.accountKey))!
        
        self.databaseConnection.readWrite { (transaction) in
            identityKeyPair.save(with: transaction)
        }
        
        return identityKeyPair
    }
    
    //MARK: Database Utilities
    
    /**
     Fetches the OTRAccountSignalIdentity for the account key from this class.
     
     returns: An OTRAccountSignalIdentity or nil if none was created and stored.
     */
    fileprivate func accountSignalIdentity() -> OTRAccountSignalIdentity? {
        var identityKeyPair:OTRAccountSignalIdentity? = nil
        self.databaseConnection.read { (transaction) in
            identityKeyPair = OTRAccountSignalIdentity.fetchObject(withUniqueID: self.accountKey, transaction: transaction)
        }
        
        return identityKeyPair
    }
    
    fileprivate func storePreKey(_ preKey: Data, preKeyId: UInt32, transaction:YapDatabaseReadWriteTransaction) -> Bool {
        guard let preKeyDatabaseObject = OTRSignalPreKey(accountKey: self.accountKey, keyId: preKeyId, keyData: preKey) else {
            return false
        }
        preKeyDatabaseObject.save(with: transaction)
        return true
    }
    
    /** 
     Save a bunch of pre keys in one database transaction
     
     - parameters preKeys: The array of pre-keys to be stored
     
     - return: Whether the storage was successufl
     */
    open func storeSignalPreKeys(_ preKeys:[SignalPreKey]) -> Bool {
        
        if preKeys.count == 0 {
            return true
        }
        
        var success = false
        self.databaseConnection.readWrite { (transaction) in
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
        self.databaseConnection.read { (transaction) in
            guard let secondaryIndexTransaction = transaction.ext(DatabaseExtensionName.secondaryIndexName.name()) as? YapDatabaseSecondaryIndexTransaction else {
                return
            }
            let query = YapDatabaseQuery.init(aggregateFunction: "MAX(\(OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName))", string: "WHERE \(OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName) = ?", parameters: ["\(self.accountKey)"])
            if let result = secondaryIndexTransaction.performAggregateQuery(query) as? NSNumber {
                maxId = result.uint32Value
            }
        }
        return maxId
    }
    
    /**
     Fetch all pre-keys for this class's account. This can include deleted pre-keys which are OTRSignalPreKey witout any keyData.
     
     - parameter includeDeleted: If deleted pre-keys are included in the result
     
     - return: An array of OTRSignalPreKey(s). If ther eare no pre-keys then the array will be empty.
     */
    internal func fetchAllPreKeys(_ includeDeleted:Bool) -> [OTRSignalPreKey] {
        var preKeys = [OTRSignalPreKey]()
        self.databaseConnection.read { (transaction) in
            guard let secondaryIndexTransaction = transaction.ext(DatabaseExtensionName.secondaryIndexName.name()) as? YapDatabaseSecondaryIndexTransaction else {
                return
            }
            
            let query = YapDatabaseQuery(string: "WHERE (OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName) = ?", parameters:  ["\(self.accountKey)"])
            secondaryIndexTransaction.enumerateKeysAndObjects(matching: query, using: { (collection, key, object, stop) in
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
    open func fetchOurExistingBundle() throws -> OTROMEMOBundleOutgoing {
        var simpleBundle:OTROMEMOBundle? = nil
        //Fetch and create the base bundle
        self.databaseConnection.read { (transaction) in
            do {
                guard let identityKeyPair = OTRAccountSignalIdentity.fetchObject(withUniqueID: self.accountKey, transaction: transaction),
                    let signedPreKeyDataObject = OTRSignalSignedPreKey.fetchObject(withUniqueID: self.accountKey, transaction: transaction) else {
                        return
                }
                let signedPreKey = try SignalSignedPreKey(serializedData: signedPreKeyDataObject.keyData)
                
                let publicIdentityKey = identityKeyPair.identityKeyPair.publicKey
                simpleBundle = OTROMEMOBundle(deviceId: identityKeyPair.registrationId, publicIdentityKey: publicIdentityKey, signedPublicPreKey: signedPreKey.keyPair().publicKey, signedPreKeyId: signedPreKey.preKeyId(), signedPreKeySignature: signedPreKey.signature())
            } catch {
                
            }
        }
        
        guard let bundle = simpleBundle else  {
            throw OMEMOBundleError.notFound
        }
        
        //Gather pieces of outgoing bundle
        let preKeys = self.fetchAllPreKeys(false)
        
        var preKeyDict = [UInt32: Data]()
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
        
        do {
            if let preKey = preKeys.first, let preKeyData = preKey.keyData {
                let _ = try SignalPreKeyBundle(registrationId: 0, deviceId: bundle.deviceId, preKeyId: preKey.keyId, preKeyPublic: preKeyData, signedPreKeyId: bundle.signedPreKeyId, signedPreKeyPublic: bundle.signedPublicPreKey, signature: bundle.signedPreKeySignature, identityKey: bundle.publicIdentityKey)
            } else {
                //DDLogError("Error fetching outgoing bundle: no prekeys")
                throw OMEMOBundleError.invalid
            }
        } catch let error {
            //DDLogError("Error fetching outgoing bundle: \(error)")
            throw error
        }
        
        return OTROMEMOBundleOutgoing(bundle: bundle, preKeys: preKeyDict as [UInt32 : Data])
    }
    
    fileprivate func fetchDeviceForSignalAddress(_ signalAddress:SignalAddress, transaction:YapDatabaseReadTransaction) -> OTROMEMODevice? {
        guard let parentEntry = self.parentKeyAndCollectionForSignalAddress(signalAddress, transaction: transaction) else {
            return nil
        }
        
        let deviceNumber = NSNumber(value: signalAddress.deviceId as Int32)
        let deviceYapKey = OTROMEMODevice.yapKey(withDeviceId: deviceNumber, parentKey: parentEntry.key, parentCollection: parentEntry.collection)
        guard let device = OTROMEMODevice.fetchObject(withUniqueID: deviceYapKey, transaction: transaction) else {
            return nil
        }
        return device
    }
    
    fileprivate func parentKeyAndCollectionForSignalAddress(_ signalAddress:SignalAddress, transaction:YapDatabaseReadTransaction) -> OTRDatabaseEntry? {
        var parentKey:String? = nil
        var parentCollection:String? = nil
        
        let ourAccount = OTRAccount.fetchObject(withUniqueID: self.accountKey, transaction: transaction)
        if ourAccount?.username == signalAddress.name {
            
            parentKey = self.accountKey
            parentCollection = OTRAccount.collection()
            
        } else if let buddy = OTRBuddy.fetch(withUsername: signalAddress.name, withAccountUniqueId: self.accountKey, transaction: transaction) {
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
    public func sessionRecord(for address: SignalAddress) -> Data? {
        let yapKey = OTRSignalSession.uniqueKey(forAccountKey: self.accountKey, name: address.name, deviceId: address.deviceId)
        var sessionData:Data? = nil
        self.databaseConnection.read { (transaction) in
            sessionData = OTRSignalSession.fetchObject(withUniqueID: yapKey, transaction: transaction)?.sessionData
        }
        return sessionData
    }
    
    public func storeSessionRecord(_ recordData: Data, for address: SignalAddress) -> Bool {
        guard let session = OTRSignalSession(accountKey: self.accountKey, name: address.name, deviceId: address.deviceId, sessionData: recordData) else {
            return false
        }
        self.databaseConnection.readWrite { (transaction) in
            session.save(with: transaction)
        }
        return true
    }
    
    public func sessionRecordExists(for address: SignalAddress) -> Bool {
        if let _ = self.sessionRecord(for: address) {
            return true
        } else {
            return false
        }
    }
    
    public func deleteSessionRecord(for address: SignalAddress) -> Bool {
        let yapKey = OTRSignalSession.uniqueKey(forAccountKey: self.accountKey, name: address.name, deviceId: address.deviceId)
        self.databaseConnection.readWrite { (transaction) in
            transaction.removeObject(forKey: yapKey, inCollection: OTRSignalSession.collection())
        }
        return true
    }
    
    public func allDeviceIds(forAddressName addressName: String) -> [NSNumber] {
        var addresses = [NSNumber]()
        self.databaseConnection.read { (transaction) in
            transaction.enumerateSessions(accountKey: self.accountKey, signalAddressName: addressName, block: { (session, stop) in
                addresses.append(NSNumber(value: session.deviceId as Int32))
            })
        }
        return addresses
    }
    
    public func deleteAllSessions(forAddressName addressName: String) -> Int32 {
        var count:Int32 = 0
        self.databaseConnection.readWrite( { (transaction) in
            var sessionKeys = [String]()
            transaction.enumerateSessions(accountKey: self.accountKey, signalAddressName: addressName, block: { (session, stop) in
                sessionKeys.append(session.uniqueId)
            })
            count = Int32(sessionKeys.count)
            for key in sessionKeys {
                transaction.removeObject(forKey: key, inCollection: OTRSignalSession.collection())
            }
        })
        return count
    }
    
    //MARK: SignalPreKeyStore
    public func loadPreKey(withId preKeyId: UInt32) -> Data? {
        var preKeyData:Data? = nil
        self.databaseConnection.read { (transaction) in
            let yapKey = OTRSignalPreKey.uniqueKey(forAccountKey: self.accountKey, keyId: preKeyId)
            if let signedPreKey = OTRSignalPreKey.fetchObject(withUniqueID: yapKey, transaction: transaction) {
                preKeyData = signedPreKey.keyData
            }
        }
        return preKeyData
    }
    
    public func storePreKey(_ preKey: Data, preKeyId: UInt32) -> Bool {
        var result = false
        self.databaseConnection.readWrite { (transaction) in
            result = self.storePreKey(preKey, preKeyId: preKeyId, transaction: transaction)
        }
        return result
    }
    
    public func containsPreKey(withId preKeyId: UInt32) -> Bool {
        if let _ = self.loadPreKey(withId: preKeyId) {
            return true
        } else {
            return false
        }
    }
    
    public func deletePreKey(withId preKeyId: UInt32) -> Bool {
        self.databaseConnection.readWrite { (transaction) in
            let yapKey = OTRSignalPreKey.uniqueKey(forAccountKey: self.accountKey, keyId: preKeyId)
            let preKey = OTRSignalPreKey.fetchObject(withUniqueID: yapKey, transaction: transaction)
            preKey?.keyData = nil
            preKey?.save(with: transaction)
        }
        return true
    }
    
    //MARK: SignalSignedPreKeyStore
    public func loadSignedPreKey(withId signedPreKeyId: UInt32) -> Data? {
        var preKeyData:Data? = nil
        self.databaseConnection.read { (transaction) in
            if let signedPreKey = OTRSignalSignedPreKey.fetchObject(withUniqueID: self.accountKey, transaction: transaction) {
                preKeyData = signedPreKey.keyData
            }
        }
        
        return preKeyData
    }
    
    public func storeSignedPreKey(_ signedPreKey: Data, signedPreKeyId: UInt32) -> Bool {
        guard let signedPreKeyDatabaseObject = OTRSignalSignedPreKey(accountKey: self.accountKey, keyId: signedPreKeyId, keyData: signedPreKey) else {
            return false
        }
        self.databaseConnection.readWrite { (transaction) in
            signedPreKeyDatabaseObject.save(with: transaction)
        }
        return true
        
    }
    
    public func containsSignedPreKey(withId signedPreKeyId: UInt32) -> Bool {
        if let _ = self.loadSignedPreKey(withId: signedPreKeyId) {
            return true
        } else {
            return false
        }
    }
    
    public func removeSignedPreKey(withId signedPreKeyId: UInt32) -> Bool {
        self.databaseConnection.readWrite { (transaction) in
            transaction.removeObject(forKey: self.accountKey, inCollection: OTRSignalSignedPreKey.collection())
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
    
    
    public func saveIdentity(_ address: SignalAddress, identityKey: Data?) -> Bool {
        var result = false
        self.databaseConnection.readWrite { (transaction) in
            if let device = self.fetchDeviceForSignalAddress(address, transaction: transaction) {
                let newDevice = OTROMEMODevice(deviceId: device.deviceId, trustLevel: device.trustLevel, parentKey: device.parentKey, parentCollection: device.parentCollection, publicIdentityKeyData: identityKey, lastSeenDate:device.lastSeenDate)
                newDevice.save(with: transaction)
                result = true
            } else if let parentEntry = self.parentKeyAndCollectionForSignalAddress(address, transaction: transaction) {
                
                //See if we have any devices
                var hasDevices = false
                OTROMEMODevice.enumerateDevices(forParentKey: parentEntry.key, collection: parentEntry.collection, transaction: transaction, using: { (device, stop) in
                    hasDevices = true
                    stop.pointee = true
                })
                
                var trustLevel = OMEMOTrustLevel.untrustedNew
                if (!hasDevices) {
                    //This is the first time we're seeing a device list for this account/buddy so it should be saved as TOFU
                    trustLevel = .trustedTofu
                }
                let deviceIdNumber = NSNumber(value: address.deviceId as Int32)
                let newDevice = OTROMEMODevice(deviceId: deviceIdNumber, trustLevel: trustLevel, parentKey: parentEntry.key, parentCollection: parentEntry.collection, publicIdentityKeyData: identityKey, lastSeenDate:Date())
                newDevice.save(with: transaction)
                result = true
            }
        }
        return result
    }
    
    
    // We always return true here because we want Signal to always encrypt and decrypt messages. We deal with trust elsewhere.
    public func isTrustedIdentity(_ address: SignalAddress, identityKey: Data) -> Bool {
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
    
    public func storeSenderKey(_ senderKey: Data, address: SignalAddress, groupId: String) -> Bool {
        self.databaseConnection.readWrite { (transaction) in
            guard let senderKey = OTRSignalSenderKey(accountKey: self.accountKey, name: address.name, deviceId: address.deviceId, groupId: groupId, senderKey: senderKey) else {
                return
            }
            senderKey.save(with: transaction)
        }
        return true
    }
    
    public func loadSenderKey(for address: SignalAddress, groupId: String) -> Data? {
        var senderKeyData:Data? = nil
        self.databaseConnection.read { (transaction) in
            let yapKey = OTRSignalSenderKey.uniqueKey(fromAccountKey: self.accountKey, name: address.name, deviceId: address.deviceId, groupId: groupId)
            let senderKey = OTRSignalSenderKey.fetchObject(withUniqueID: yapKey, transaction: transaction)
            senderKeyData = senderKey?.senderKey
        }
        return senderKeyData
    }
}
