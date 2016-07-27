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

class OTRSignalEncryptionManager {
    
    let storage:OTRSignalStorageManager
    let signalContext:SignalContext
    let signalKeyHelper:SignalKeyHelper
    
    init(accountKey:String, databaseConnection:YapDatabaseConnection) {
        self.storage = OTRSignalStorageManager(accountKey: accountKey, databaseConnection: databaseConnection, delegate: nil)
        let signalStorage = SignalStorage(signalStore: self.storage)
        self.signalContext = SignalContext(storage: signalStorage)!
        self.signalKeyHelper = SignalKeyHelper(context: self.signalContext)!
        self.storage.delegate = self
    }

}

extension OTRSignalEncryptionManager: OTRSignalStorageManagerDelegate {
    
    func generateNewIdenityKeyPairForAccountKey(accountKey:String) -> OTRAccountSignalIdentity {
        let keyPair = self.signalKeyHelper.generateIdentityKeyPair()!
        let registrationId = self.signalKeyHelper.generateRegistrationId()
        return OTRAccountSignalIdentity(accountKey: accountKey, identityKeyPair: keyPair, registrationId: registrationId)!
    }
}