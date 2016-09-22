//
//  OTRSignalStorageManager.swift
//  ChatSecure
//
//  Created by David Chiles on 7/21/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import SignalProtocol_ObjC
import YapDatabase

public protocol OTRSignalStorageManagerDelegate: class {
    /** Generate a new account key*/
    func generateNewIdenityKeyPairForAccountKey(accountKey:String) -> OTRAccountSignalIdentity
}

/**
 * This class implements the SignalStore protocol. One OTRSignalStorageManager should be created per account key.
 * This interfaces to the yap database 
 */
public class OTRSignalStorageManager: NSObject, SignalStore {
    public let accountKey:String
    public let databaseConnection:YapDatabaseConnection
    public weak var delegate:OTRSignalStorageManagerDelegate?
    
    
    public init(accountKey:String, databaseConnection:YapDatabaseConnection, delegate:OTRSignalStorageManagerDelegate?) {
        self.accountKey = accountKey
        self.databaseConnection = databaseConnection
        self.delegate = delegate
    }
    
    private func generateNewIdenityKeyPair() -> OTRAccountSignalIdentity {
        // Might be a better way to guarantee we have an OTRAccountSignalIdentity
        let identityKeyPair = (self.delegate?.generateNewIdenityKeyPairForAccountKey(self.accountKey))!
        
        self.databaseConnection.readWriteWithBlock { (transaction) in
            identityKeyPair.saveWithTransaction(transaction)
        }
        
        return identityKeyPair
    }
    
    //MARK: Database Utilities
    
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
    
    /** Save a bunch of pre keys in one database transaction */
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
    
//    internal func fetchAllPreKeys(includeDeleted:Bool) -> [OTRSignalPreKey] {
//        self.databaseConnection.readWithBlock { (transaction) in
//            guard let secondaryIndexTransaction = transaction.ext(DatabaseExtensionName.SecondaryIndexName.name()) as? YapDatabaseSecondaryIndexTransaction else {
//                return
//            }
//            
//            let query = YapDatabaseQuery(string: "WHERE (OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName) = ?", parameters:  ["\(self.accountKey)"])
//            secondaryIndexTransaction
//            
//        }
//    }
    
//    public func fetchOurExistingBundle() -> OTROMEMOBundleOutgoing? {
//        var bundle:OTROMEMOBundleOutgoing? = nil
//        self.databaseConnection.readWithBlock { (transaction) in
//            
//            do {
//                guard let identityKeyPair = OTRAccountSignalIdentity.fetchObjectWithUniqueID(self.accountKey, transaction: transaction),
//                    let signedPreKeyDataObject = OTRSignalSignedPreKey.fetchObjectWithUniqueID(self.accountKey, transaction: transaction) else {
//                        return
//                }
//                let signedPreKey = try SignalSignedPreKey(serializedData: signedPreKeyDataObject.keyData)
//                
//                let publicIdentityKey = identityKeyPair.identityKeyPair.publicKey
//                
//                
//                let simpleBundle = OTROMEMOBundle(deviceId: identityKeyPair.registrationId, publicIdentityKey: publicIdentityKey, signedPublicPreKey: signedPreKey.keyPair().publicKey, signedPreKeyId: signedPreKey.preKeyId(), signedPreKeySignature: signedPreKey.signature())
//                
//                
//                bundle = OTROMEMOBundleOutgoing(bundle: simpleBundle, preKeys: <#T##[UInt32 : NSData]#>)
//                
//            } catch {
//                return
//            }
//            
//            
//            
//        }
//        return bundle
//    }
    
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
        }
        //Generate new registration ID?
        return self.generateNewIdenityKeyPair().registrationId
    }
    
    public func saveIdentity(name: String, identityKey: NSData?) -> Bool {
        let yapKey = OTRSignalIdentityKey.uniqueKeyFromAccountKey(self.accountKey, name: name)
        self.databaseConnection.readWriteWithBlock { (transaction) in
            if let data = identityKey {
                //Save to database
                guard let identityKey = OTRSignalIdentityKey(accountKey: self.accountKey, name: name, identityKey: data) else {
                    return
                }
                identityKey.saveWithTransaction(transaction)
            } else {
                //Remove from database
                transaction.removeObjectForKey(yapKey, inCollection: OTRSignalIdentityKey.collection())
            }
        }
        return true
    }
    
    public func isTrustedIdentity(name: String, identityKey: NSData) -> Bool {
        let yapKey = OTRSignalIdentityKey.uniqueKeyFromAccountKey(self.accountKey, name: name)
        var idenittyKey:OTRSignalIdentityKey? = nil
        self.databaseConnection.readWithBlock { (transaction) in
            idenittyKey = OTRSignalIdentityKey.fetchObjectWithUniqueID(yapKey, transaction: transaction)
        }
        
        guard let data = idenittyKey?.identityKey else {
            return true
        }
        
        return data.isEqualToData(identityKey)
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
