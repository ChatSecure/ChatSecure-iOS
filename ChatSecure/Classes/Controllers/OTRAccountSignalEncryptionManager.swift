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

public enum SignalEncryptionError:Error {
    case unableToCreateSignalContext
}

/* Performs any Signal operations: creating bundle, decryption, encryption. Use one OTRAccountSignalEncryptionManager per account **/
open class OTRAccountSignalEncryptionManager {
    
    let storage:OTRSignalStorageManager
    var signalContext:SignalContext
    
    //In OMEMO world the registration ID is used as the device id and all devices have registration ID of 0.
    open var registrationId:UInt32 {
        get {
            return self.storage.getLocalRegistrationId()
        }
    }
    
    open var identityKeyPair:SignalIdentityKeyPair {
        get {
            return self.storage.getIdentityKeyPair()
        }
    }
    
    init(accountKey:String, databaseConnection:YapDatabaseConnection) throws {
        self.storage = OTRSignalStorageManager(accountKey: accountKey, databaseConnection: databaseConnection, delegate: nil)
        let signalStorage = SignalStorage(signalStore: self.storage)
        guard let context = SignalContext(storage: signalStorage) else {
            throw SignalEncryptionError.unableToCreateSignalContext
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
        guard let signedPreKey = self.keyHelper()?.generateSignedPreKey(withIdentity: self.identityKeyPair, signedPreKeyId:preKeyId),
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
    public func generateOutgoingBundle(_ preKeyCount:UInt) throws -> OTROMEMOBundleOutgoing {
        
        guard let signedPreKey = self.generateRandomSignedPreKey(), let data = signedPreKey.serializedData() else {
            throw OMEMOBundleError.keyGeneration
        }
        
        let publicIdentityKey = self.storage.getIdentityKeyPair().publicKey
        let deviceId = self.registrationId
        guard let preKeys = self.generatePreKeys(1, count: preKeyCount) else {
            throw OMEMOBundleError.keyGeneration
        }
        
        var preKeyDict = [UInt32:Data]()
        for preKey in preKeys {
            preKeyDict.updateValue(preKey.keyPair().publicKey, forKey: preKey.preKeyId())
        }
        
        let bundle = OTROMEMOBundle(deviceId: deviceId, publicIdentityKey: publicIdentityKey, signedPublicPreKey: signedPreKey.keyPair().publicKey, signedPreKeyId: signedPreKey.preKeyId(), signedPreKeySignature: signedPreKey.signature())
        
        do {
            if let preKey = preKeys.first {
                let _ = try SignalPreKeyBundle(registrationId: 0, deviceId: bundle.deviceId, preKeyId: preKey.preKeyId(), preKeyPublic: preKey.keyPair().publicKey, signedPreKeyId: bundle.signedPreKeyId, signedPreKeyPublic: bundle.signedPublicPreKey, signature: bundle.signedPreKeySignature, identityKey: bundle.publicIdentityKey)
            } else {
                //DDLogError("Error testing outgoing bundle")
                throw OMEMOBundleError.invalid
            }
        } catch let error {
            //DDLogError("Error creating outgoing bundle: \(error)")
            throw OMEMOBundleError.invalid
        }
        
        _ = self.storage.storeSignedPreKey(data, signedPreKeyId: signedPreKey.preKeyId())
        return OTROMEMOBundleOutgoing(bundle: bundle, preKeys: preKeyDict)
    }
    
    /**
     * This processes fetched OMEMO bundles. After you consume a bundle you can then create preKeyMessages to send to the contact.
     */
    public func consumeIncomingBundle(_ name:String, bundle:OTROMEMOBundleIncoming) throws {
        let deviceId = Int32(bundle.bundle.deviceId)
        let incomingAddress = SignalAddress(name: name.lowercased(), deviceId: deviceId)
        let sessionBuilder = SignalSessionBuilder(address: incomingAddress, context: self.signalContext)
        let preKeyBundle = try SignalPreKeyBundle(registrationId: 0, deviceId: bundle.bundle.deviceId, preKeyId: bundle.preKeyId, preKeyPublic: bundle.preKeyData, signedPreKeyId: bundle.bundle.signedPreKeyId, signedPreKeyPublic: bundle.bundle.signedPublicPreKey, signature: bundle.bundle.signedPreKeySignature, identityKey: bundle.bundle.publicIdentityKey)
        
        return try sessionBuilder.processPreKeyBundle(preKeyBundle)
    }
    
    public func encryptToAddress(_ data:Data, name:String, deviceId:UInt32) throws -> SignalCiphertext {
        let address = SignalAddress(name: name.lowercased(), deviceId: Int32(deviceId))
        let sessionCipher = SignalSessionCipher(address: address, context: self.signalContext)
        return try sessionCipher.encryptData(data)
    }
    
    public func decryptFromAddress(_ data:Data, name:String, deviceId:UInt32) throws -> Data {
        let address = SignalAddress(name: name.lowercased(), deviceId: Int32(deviceId))
        let sessionCipher = SignalSessionCipher(address: address, context: self.signalContext)
        let cipherText = SignalCiphertext(data: data, type: .unknown)
        return try sessionCipher.decryptCiphertext(cipherText)
    }
    
    
    public func generatePreKeys(_ start:UInt, count:UInt) -> [SignalPreKey]? {
        guard let preKeys = self.keyHelper()?.generatePreKeys(withStartingPreKeyId: start, count: count) else {
            return nil
        }
        if self.storage.storeSignalPreKeys(preKeys) {
            return preKeys
        }
        return nil
    }
    
    public func sessionRecordExistsForUsername(_ username:String, deviceId:Int32) -> Bool {
        let address = SignalAddress(name: username.lowercased(), deviceId: deviceId)
        return self.storage.sessionRecordExists(for: address)
    }
    
    public func removeSessionRecordForUsername(_ username:String, deviceId:Int32) -> Bool {
        let address = SignalAddress(name: username.lowercased(), deviceId: deviceId)
        return self.storage.deleteSessionRecord(for: address)
    }
}

extension OTRAccountSignalEncryptionManager: OTRSignalStorageManagerDelegate {
    
    public func generateNewIdenityKeyPairForAccountKey(_ accountKey:String) -> OTRAccountSignalIdentity {
        let keyHelper = self.keyHelper()!
        let keyPair = keyHelper.generateIdentityKeyPair()!
        let registrationId = keyHelper.generateRegistrationId()
        return OTRAccountSignalIdentity(accountKey: accountKey, identityKeyPair: keyPair, registrationId: registrationId)!
    }
}
