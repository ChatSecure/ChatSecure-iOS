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
    let signalKeyHelper:SignalKeyHelper
    
    public var deviceId:UInt32 {
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
        self.signalKeyHelper = SignalKeyHelper(context: self.signalContext)!
        self.storage.delegate = self
    }
}

extension OTRAccountSignalEncryptionManager {
    public func generateRandomSignedPreKey() -> SignalSignedPreKey? {
        guard let signedPreKey = self.signalKeyHelper.generateSignedPreKeyWithIdentity(self.identityKeyPair, signedPreKeyId: arc4random()),
            let data = signedPreKey.serializedData() else {
            return nil
        }
        if self.storage.storeSignedPreKey(data, signedPreKeyId: signedPreKey.preKeyId()) {
            return signedPreKey
        }
        return nil
    }
    
    //TODO: How do you know where to start?
    public func generatePreKeys(start:UInt, count:UInt) -> [SignalPreKey]? {
        let preKeys = self.signalKeyHelper.generatePreKeysWithStartingPreKeyId(start, count: count)
        if self.storage.storeSignalPreKeys(preKeys) {
            return preKeys
        }
        return nil
    }
}

extension OTRAccountSignalEncryptionManager: OTRSignalStorageManagerDelegate {
    
    public func generateNewIdenityKeyPairForAccountKey(accountKey:String) -> OTRAccountSignalIdentity {
        let keyPair = self.signalKeyHelper.generateIdentityKeyPair()!
        let registrationId = self.signalKeyHelper.generateRegistrationId()
        return OTRAccountSignalIdentity(accountKey: accountKey, identityKeyPair: keyPair, registrationId: registrationId)!
    }
}