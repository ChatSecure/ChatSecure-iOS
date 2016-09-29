//
//  OTROMEMOSignalCoordinator.swift
//  ChatSecure
//
//  Created by David Chiles on 8/4/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import XMPPFramework
import YapDatabase

/** 
 * This is the glue between XMPP/OMEMO and Signal
 */
@objc public class OTROMEMOSignalCoordinator: NSObject {
    
    public let signalEncryptionManager:OTRAccountSignalEncryptionManager
    public let omemoStorageManager:OTROMEMOStorageManager
    public let accountYapKey:String
    public weak var omemoModule:OMEMOModule?
    public weak var omemoModuleQueue:dispatch_queue_t?
    private var myJID:XMPPJID? {
        get {
            return omemoModule?.xmppStream.myJID
        }
    }
    let workQueue:dispatch_queue_t
    let preKeyCount:UInt = 100
    
    @objc public init(accountYapKey:String,  databaseConnection:YapDatabaseConnection) {
        self.signalEncryptionManager = OTRAccountSignalEncryptionManager(accountKey: accountYapKey,databaseConnection: databaseConnection)
        self.omemoStorageManager = OTROMEMOStorageManager(accountKey: accountYapKey, accountCollection: OTRAccount.collection(), databaseConnection: databaseConnection)
        self.accountYapKey = accountYapKey
        self.workQueue = dispatch_queue_create("OTROMEMOSignalCoordinator-work-queue", DISPATCH_QUEUE_SERIAL)
    }
    
    private func isOurJID(jid:XMPPJID) -> Bool {
        guard let ourJID = self.myJID else {
            return false;
        }
        
        return jid.isEqualToJID(ourJID, options: XMPPJIDCompareBare)
    }

}

extension OTROMEMOSignalCoordinator:OMEMOStorageDelegate {
    
    public func configureWithParent(aParent: OMEMOModule, queue: dispatch_queue_t) -> Bool {
        self.omemoModule = aParent
        self.omemoModuleQueue = queue
        return true
    }
    
    public func storeDeviceIds(deviceIds: [NSNumber], forJID jid: XMPPJID) {
        
        let isOurDeviceList = self.isOurJID(jid)
        
        if (isOurDeviceList) {
            self.omemoStorageManager.storeOurDevices(deviceIds)
        } else {
            self.omemoStorageManager.storeBuddyDevices(deviceIds, buddyUsername: jid.bare())
        }
    }
    
    public func fetchDeviceIdsForJID(jid: XMPPJID) -> [NSNumber] {
        var devices:[OTROMEMODevice]?
        if self.isOurJID(jid) {
            devices = self.omemoStorageManager.getDevicesForOurAccount()
            
        } else {
            devices = self.omemoStorageManager.getDevicesForBuddy(jid.bare())
        }
        
        return (devices?.map({ (device) -> NSNumber in
            return device.deviceId
        })) ?? [NSNumber]()
        
    }

    //Always returns most complete bundle with correct count of prekeys
    public func fetchMyBundle() -> OMEMOBundle? {
        
        guard let bundle = self.signalEncryptionManager.storage.fetchOurExistingBundle() ?? self.signalEncryptionManager.generateOutgoingBundle(self.preKeyCount) else {
            return nil
        }
        
        var preKeys = bundle.preKeys
        
        let keysToGenerate = Int(self.preKeyCount) - preKeys.count
        
        //Check if we don't have all the prekeys we need
        if (keysToGenerate > 0) {
            var start:UInt = 0
            if let maxId = self.signalEncryptionManager.storage.currentMaxPreKeyId() {
                start = UInt(maxId) + 1
            }
            
            let newPreKeys = self.signalEncryptionManager.generatePreKeys(start, count: UInt(keysToGenerate))
            newPreKeys?.forEach({ (preKey) in
                preKeys.updateValue(preKey.keyPair().publicKey, forKey: preKey.preKeyId())
            })
        }
        
        var preKeysArray = [OMEMOPreKey]()
        preKeys.forEach { (id,data) in
            let omemoPreKey = OMEMOPreKey(preKeyId: id, publicKey: data)
            preKeysArray.append(omemoPreKey)
        }
        
        let omemoSignedPreKey = OMEMOSignedPreKey(preKeyId: bundle.bundle.signedPreKeyId, publicKey: bundle.bundle.signedPublicPreKey, signature: bundle.bundle.signedPreKeySignature)
        return OMEMOBundle(deviceId: bundle.bundle.deviceId, identityKey: bundle.bundle.publicIdentityKey, signedPreKey: omemoSignedPreKey, preKeys: preKeysArray)
    }

    public func isSessionValid(jid: XMPPJID, deviceId: gl_uint32_t) -> Bool {
        return self.signalEncryptionManager.sessionRecordExistsForUsername(jid.bare(), deviceId: Int32(deviceId))
    }
}
