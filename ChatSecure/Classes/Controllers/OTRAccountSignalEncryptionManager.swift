//
//  OTRSignalEncryptionManager.swift
//  ChatSecure
//
//  Created by David Chiles on 7/27/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import SignalProtocolObjC
import YapDatabase

public enum SignalEncryptionError:ErrorType {
    case UnableToCreateSignalContext
}

/* Performs any Signal operations: creating bundle, decryption, encryption. Use one OTRAccountSignalEncryptionManager per account **/
public class OTRAccountSignalEncryptionManager {
    
    let storage:OTRSignalStorageManager
    var signalContext:SignalContext
    
    //In OMEMO world the registration ID is used as the device id and all devices have registration ID of 0.
    public var registrationId:UInt32 {
        get {
            return self.storage.getLocalRegistrationId()
        }
    }
    
    public var identityKeyPair:SignalIdentityKeyPair {
        get {
            return self.storage.getIdentityKeyPair()
        }
    }
    
    init(accountKey:String, databaseConnection:YapDatabaseConnection) throws {
        self.storage = OTRSignalStorageManager(accountKey: accountKey, databaseConnection: databaseConnection, delegate: nil)
        let signalStorage = SignalStorage(signalStore: self.storage)
        guard let context = SignalContext(storage: signalStorage) else {
            throw SignalEncryptionError.UnableToCreateSignalContext
        }
        self.signalContext = context
        self.storage.delegate = self
    }
}

extension OTRAccountSignalEncryptionManager {
    internal func keyHelper() -> SignalKeyHelper? {
        return SignalKeyHelper(context: self.signalContext)
    }
    
    public func generateRandomSignedPreKey() -> SignalSignedPreKey? {
        
        guard let preKeyId = self.keyHelper()?.generateRegistrationId() else {
            return nil
        }
        guard let signedPreKey = self.keyHelper()?.generateSignedPreKeyWithIdentity(self.identityKeyPair, signedPreKeyId:preKeyId),
            let data = signedPreKey.serializedData() else {
            return nil
        }
        if self.storage.storeSignedPreKey(data, signedPreKeyId: signedPreKey.preKeyId()) {
            return signedPreKey
        }
        return nil
    }
    
    /** 
     * This creates all the information necessary to publish a 'bundle' to your XMPP server via PEP. It generates prekeys 0 to 99.
     */
    public func generateOutgoingBundle(preKeyCount:UInt) -> OTROMEMOBundleOutgoing? {
        
        guard let signedPreKey = self.generateRandomSignedPreKey(), let data = signedPreKey.serializedData() else {
            return nil
        }
        self.storage.storeSignedPreKey(data, signedPreKeyId: signedPreKey.preKeyId())
        
        let publicIdentityKey = self.storage.getIdentityKeyPair().publicKey
        let deviceId = self.registrationId
        guard let preKeys = self.generatePreKeys(1, count: preKeyCount) else {
            return nil
        }
        
        var preKeyDict = [UInt32:NSData]()
        for preKey in preKeys {
            preKeyDict.updateValue(preKey.keyPair().publicKey, forKey: preKey.preKeyId())
        }
        
        let bundle = OTROMEMOBundle(deviceId: deviceId, publicIdentityKey: publicIdentityKey, signedPublicPreKey: signedPreKey.keyPair().publicKey, signedPreKeyId: signedPreKey.preKeyId(), signedPreKeySignature: signedPreKey.signature())
        return OTROMEMOBundleOutgoing(bundle: bundle, preKeys: preKeyDict)
    }
    
    /**
     * This processes fetched OMEMO bundles. After you consume a bundle you can then create preKeyMessages to send to the contact.
     */
    public func consumeIncomingBundle(name:String, bundle:OTROMEMOBundleIncoming) {
        let deviceId = Int32(bundle.bundle.deviceId)
        let incomingAddress = SignalAddress(name: name.lowercaseString, deviceId: deviceId)
        let sessionBuilder = SignalSessionBuilder(address: incomingAddress, context: self.signalContext)
        let preKeyBundle = SignalPreKeyBundle(registrationId: 0, deviceId: bundle.bundle.deviceId, preKeyId: bundle.preKeyId, preKeyPublic: bundle.preKeyData, signedPreKeyId: bundle.bundle.signedPreKeyId, signedPreKeyPublic: bundle.bundle.signedPublicPreKey, signature: bundle.bundle.signedPreKeySignature, identityKey: bundle.bundle.publicIdentityKey)
        
        sessionBuilder.processPreKeyBundle(preKeyBundle)
    }
    
    public func encryptToAddress(data:NSData, name:String, deviceId:UInt32) throws -> SignalCiphertext {
        let address = SignalAddress(name: name.lowercaseString, deviceId: Int32(deviceId))
        let sessionCipher = SignalSessionCipher(address: address, context: self.signalContext)
        return try sessionCipher.encryptData(data)
    }
    
    public func decryptFromAddress(data:NSData, name:String, deviceId:UInt32) throws -> NSData {
        let address = SignalAddress(name: name.lowercaseString, deviceId: Int32(deviceId))
        let sessionCipher = SignalSessionCipher(address: address, context: self.signalContext)
        let cipherText = SignalCiphertext(data: data, type: .Unknown)
        return try sessionCipher.decryptCiphertext(cipherText)
    }
    
    
    public func generatePreKeys(start:UInt, count:UInt) -> [SignalPreKey]? {
        guard let preKeys = self.keyHelper()?.generatePreKeysWithStartingPreKeyId(start, count: count) else {
            return nil
        }
        if self.storage.storeSignalPreKeys(preKeys) {
            return preKeys
        }
        return nil
    }
    
    public func sessionRecordExistsForUsername(username:String, deviceId:Int32) -> Bool {
        let address = SignalAddress(name: username.lowercaseString, deviceId: deviceId)
        return self.storage.sessionRecordExistsForAddress(address)
    }
    
    public func removeSessionRecordForUsername(username:String, deviceId:Int32) -> Bool {
        let address = SignalAddress(name: username.lowercaseString, deviceId: deviceId)
        return self.storage.deleteSessionRecordForAddress(address)
    }
}

extension OTRAccountSignalEncryptionManager: OTRSignalStorageManagerDelegate {
    
    public func generateNewIdenityKeyPairForAccountKey(accountKey:String) -> OTRAccountSignalIdentity {
        let keyHelper = self.keyHelper()!
        let keyPair = keyHelper.generateIdentityKeyPair()!
        let registrationId = keyHelper.generateRegistrationId()
        return OTRAccountSignalIdentity(accountKey: accountKey, identityKeyPair: keyPair, registrationId: registrationId)!
    }
}
