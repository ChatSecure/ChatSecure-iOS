//
//  OTRSignalEncryptionManager.swift
//  ChatSecure
//
//  Created by David Chiles on 7/27/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import SignalProtocol_ObjC
import YapDatabase

/* Performs any Signal operations: creating bundle, decryption, encryption. Use one OTRAccountSignalEncryptionManager per account**/
public class OTRAccountSignalEncryptionManager {
    
    let storage:OTRSignalStorageManager
    let signalContext:SignalContext
    
    //Don't think this is used for anything? Looks like in Conversations they use 0.
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
    
    init(accountKey:String, databaseConnection:YapDatabaseConnection) {
        self.storage = OTRSignalStorageManager(accountKey: accountKey, databaseConnection: databaseConnection, delegate: nil)
        let signalStorage = SignalStorage(signalStore: self.storage)
        self.signalContext = SignalContext(storage: signalStorage)!
        self.storage.delegate = self
    }
}

extension OTRAccountSignalEncryptionManager {
    internal func keyHelper() -> SignalKeyHelper? {
        return SignalKeyHelper(context: self.signalContext)
    }
    
    public func generateRandomSignedPreKey() -> SignalSignedPreKey? {
        guard let signedPreKey = self.keyHelper()?.generateSignedPreKeyWithIdentity(self.identityKeyPair, signedPreKeyId: arc4random()),
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
    public func generateOurNewBundle() -> OTROMEMOBundle? {
        
        guard let signedPreKey = self.generateRandomSignedPreKey(), let data = signedPreKey.serializedData() else {
            return nil
        }
        self.storage.storeSignedPreKey(data, signedPreKeyId: signedPreKey.preKeyId())
        
        let publicIdentityKey = self.storage.getIdentityKeyPair().publicKey
        let deviceId = self.registrationId
        guard let preKeys = self.generatePreKeys(0, count: 100) else {
            return nil
        }
        
        var preKeyDict = [UInt32:NSData]()
        for preKey in preKeys {
            preKeyDict.updateValue(preKey.keyPair().publicKey, forKey: preKey.preKeyId())
        }
        
        return OTROMEMOBundle(deviceId: deviceId, publicIdentityKey: publicIdentityKey, signedPublicPreKey: signedPreKey.keyPair().publicKey, signedPreKeyId: signedPreKey.preKeyId(), signedPreKeySignature: signedPreKey.signature(), preKeys: preKeyDict)
        
    }
    
    //TODO: How do you know where to start?
    public func generatePreKeys(start:UInt, count:UInt) -> [SignalPreKey]? {
        guard let preKeys = self.keyHelper()?.generatePreKeysWithStartingPreKeyId(start, count: count) else {
            return nil
        }
        if self.storage.storeSignalPreKeys(preKeys) {
            return preKeys
        }
        return nil
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