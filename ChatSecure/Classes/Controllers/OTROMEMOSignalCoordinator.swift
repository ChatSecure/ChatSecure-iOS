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
    public let databaseConnection:YapDatabaseConnection
    public weak var omemoModule:OMEMOModule?
    public weak var omemoModuleQueue:dispatch_queue_t?
    public var callbackQueue:dispatch_queue_t
    public let workQueue:dispatch_queue_t
    private var myJID:XMPPJID? {
        get {
            return omemoModule?.xmppStream.myJID
        }
    }
    let preKeyCount:UInt = 100
    private var outstandingDeviceBundleRequests:[String: (Bool) -> Void]
    /**
     Create a OTROMEMOSignalCoordinator for an account. 
     
     - parameter accountYapKey: The accounts unique yap key
     - parameter databaseConnection: A yap database connection on which all operations will be completed on
 `  */
    @objc public required init(accountYapKey:String,  databaseConnection:YapDatabaseConnection) throws {
        try self.signalEncryptionManager = OTRAccountSignalEncryptionManager(accountKey: accountYapKey,databaseConnection: databaseConnection)
        self.omemoStorageManager = OTROMEMOStorageManager(accountKey: accountYapKey, accountCollection: OTRAccount.collection(), databaseConnection: databaseConnection)
        self.accountYapKey = accountYapKey
        self.databaseConnection = databaseConnection
        self.outstandingDeviceBundleRequests = [:]
        self.callbackQueue = dispatch_queue_create("OTROMEMOSignalCoordinator-callback", DISPATCH_QUEUE_SERIAL)
        self.workQueue = dispatch_queue_create("OTROMEMOSignalCoordinator-work", DISPATCH_QUEUE_SERIAL)
    }
    
    /**
     Checks that a jid matches our own JID using XMPPJIDCompareBare
     */
    private func isOurJID(jid:XMPPJID) -> Bool {
        guard let ourJID = self.myJID else {
            return false;
        }
        
        return jid.isEqualToJID(ourJID, options: XMPPJIDCompareBare)
    }
    
    /** Always call on internal work queue */
    private func callAndRemoveOutstandingBundleBlock(elementId:String,success:Bool) {
        
        guard let outstandingBlock = self.outstandingDeviceBundleRequests[elementId] else {
            return
        }
        outstandingBlock(success)
        self.outstandingDeviceBundleRequests.removeValueForKey(elementId)
    }
    
    /**
     Check if a buddy supports OMEMO. This checks if we've seen devices for this buddy.
     
     - parameter buddyYapKey: The yap key of the buddy.
     
     - returns: True if there are devices and the buddy supports OMEMO otherwise false.
     */
    public func buddySupportsOMEMO(buddyYapKey:String) -> Bool {
        return self.omemoStorageManager.getDevicesForParentYapKey(buddyYapKey, yapCollection: OTRBuddy.collection()).count > 0
    }
    
    /** 
     This must be called before sending every message. It ensures that for every device there is a session and if not the bundles are fetched.
     
     - parameter buddyYapKey: The yap key for the buddy to check
     - parameter completion: The completion closure called on callbackQueue. If it successfully was able to fetch all the bundles or if it wasn't necessary. If there were no devices for this buddy it will also return flase
     */
    public func prepareSessionForBuddy(buddyYapKey:String, completion:(Bool) -> Void) {
        self.prepareSession(buddyYapKey, yapCollection: OTRBuddy.collection(), completion: completion)
    }
    
    /**
     This must be called before sending every message. It ensures that for every device there is a session and if not the bundles are fetched.
     
     - parameter yapKey: The yap key for the buddy or account to check
     - parameter yapCollection: The yap key for the buddy or account to check
     - parameter completion: The completion closure called on callbackQueue. If it successfully was able to fetch all the bundles or if it wasn't necessary. If there were no devices for this buddy it will also return flase
     */
    public func prepareSession(yapKey:String, yapCollection:String, completion:(Bool) -> Void) {
        var devices:[OTROMEMODevice]? = nil
        var user:String? = nil
        
        //Get all the devices ID's for this buddy as well as their username for use with signal and XMPPFramework.
        self.databaseConnection.readWithBlock { (transaction) in
            let dev = self.omemoStorageManager.getDevicesForParentYapKey(yapKey, yapCollection: yapCollection,transaction: transaction)
            if (dev.count == 0) {
                //No devices so we can't go any further.
                dispatch_async(self.callbackQueue, { 
                    completion(false)
                })
                return
            }
            devices = dev
            if let object = transaction.objectForKey(yapKey, inCollection: yapCollection) {
                if object is OTRAccount {
                    user = object.username
                } else if object is OTRBuddy {
                    user = object.username
                }
            }
        }
        
        guard let devs = devices, let username = user else {
            dispatch_async(self.callbackQueue, {
                completion(false)
            })
            return
        }
        var finalSuccess = true
        dispatch_async(self.workQueue) { 
            let group = dispatch_group_create()
            //For each device Check if we have a session. If not then we need to fetch it from their XMPP server.
            for device in devs where device.deviceId.unsignedIntValue != self.signalEncryptionManager.registrationId {
                if !self.signalEncryptionManager.sessionRecordExistsForUsername(username, deviceId: device.deviceId.intValue) {
                    //No session for this buddy and device combo. We need to fetch the bundle.
                    
                    let elementId = NSUUID().UUIDString
                    
                    dispatch_group_enter(group)
                    // Hold on to a closure so that when we get the call back from OMEMOModule we can call this closure.
                    self.outstandingDeviceBundleRequests[elementId] = { success in
                        if (!success) {
                            finalSuccess = false
                        }
                        
                        dispatch_group_leave(group)
                    }
                    //Fetch the bundle
                    self.omemoModule?.fetchBundleForDeviceId(device.deviceId.unsignedIntValue, jid: XMPPJID.jidWithString(username), elementId: elementId)
                }
            }
            
            dispatch_group_notify(group, self.callbackQueue) {
                completion(finalSuccess)
            }
        }
    }
    
    /**
     Check if we have valid sessions with our other devices and if not fetch their bundles and start sessions.
     */
    func prepareSessionWithOurDevices(completion:(success:Bool) -> Void) {
        self.prepareSession(self.accountYapKey, yapCollection: OTRAccount.collection(), completion: completion)
    }
    
    /** 
     Gathers necessary information to encrypt a message to the buddy and all this accounts devices that are trusted. Then sends the payload via OMEMOModule
     
     - parameter messageBody: The boddy of the message
     - parameter buddyYapKey: The unique buddy yap key. Used for looking up the username and devices 
     - parameter messageId: The preffered XMPP element Id to be used.
     */
    public func encryptAndSendMessage(messageBody:String, buddyYapKey:String, messageId:String?, completion:(Bool,NSError?) -> Void) {
        // Gather bundles for buddy and account here
        let group = dispatch_group_create()
        
        let prepareCompletion = { (success:Bool) in
            dispatch_group_leave(group)
        }
        
        dispatch_group_enter(group)
        dispatch_group_enter(group)
        self.prepareSessionForBuddy(buddyYapKey, completion: prepareCompletion)
        self.prepareSessionWithOurDevices(prepareCompletion)
        //Even if something went wrong fetching bundles we should push ahead. We may have sessions that can be used.
        
        dispatch_group_notify(group, self.workQueue) { 
            var bud:OTRBuddy? = nil
            self.databaseConnection.readWithBlock { (transaction) in
                bud = OTRBuddy.fetchObjectWithUniqueID(buddyYapKey, transaction: transaction)
            }
            
            guard let ivData = OTRSignalEncryptionHelper.generateIV(), let keyData = OTRSignalEncryptionHelper.generateSymmetricKey(), let messageBodyData = messageBody.dataUsingEncoding(NSUTF8StringEncoding) , let buddy = bud else {
                return
            }
            do {
                //Create the encrypted payload
                let payload = try OTRSignalEncryptionHelper.encryptData(messageBodyData, key: keyData, iv: ivData)
                
                //Get our Buddy's device
                let buddyDevices = self.omemoStorageManager.getDevicesForParentYapKey(buddy.uniqueId, yapCollection: OTRBuddy.collection())
                //Get our Devices
                let ourDevices = self.omemoStorageManager.getDevicesForOurAccount()
                // Combine teh two arrays for all devices
                let devices = buddyDevices + ourDevices
                //Grab devices for this account
                
                var keyDataArray: [OMEMOKeyData] = []
                // Encrypt to all devices (ours and theirs) except this device
                for device in devices where device.deviceId.unsignedIntValue != self.signalEncryptionManager.registrationId {
                    if (device.trustLevel == .TrustLevelTrustedTofu || device.trustLevel == .TrustLevelUntrustedNew) {
                        do {
                            let encryptedKeyData = try self.signalEncryptionManager.encryptToAddress(keyData, name: buddy.username, deviceId: device.deviceId.unsignedIntValue)
                            let keyData = OMEMOKeyData(deviceId: device.deviceId.unsignedIntValue, data: encryptedKeyData.data)
                            keyDataArray.append(keyData)
                        } catch {
                            //Don't need to handle the error here just push forward adn keep on trying to encrypt the key
                        }
                    }
                }
                
                //Make sure we have encrypted the symetric key to someone
                if (keyDataArray.count > 0) {
                    self.omemoModule?.sendKeyData(keyDataArray, iv: ivData, toJID: XMPPJID.jidWithString(buddy.username), payload: payload?.data, elementId: messageId)
                    dispatch_async(self.callbackQueue, {
                        completion(true,nil)
                    })
                    return
                } else {
                    dispatch_async(self.callbackQueue, {
                        completion(false,nil)
                    })
                    return
                }
            } catch let err as NSError {
                //This should only happen if we had an error encrypting the payload
                dispatch_async(self.callbackQueue, {
                    completion(false,err)
                })
                return
            }
            
        }
    }
}

extension OTROMEMOSignalCoordinator: OMEMOModuleDelegate {
    
    public func omemo(omemo: OMEMOModule, publishedDeviceIds deviceIds: [NSNumber], responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        //print("publishedDeviceIds: \(responseIq)")
    }
    
    public func omemo(omemo: OMEMOModule, failedToPublishDeviceIds deviceIds: [NSNumber], errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        //print("failedToPublishDeviceIds: \(errorIq)")
    }
    
    public func omemo(omemo: OMEMOModule, deviceListUpdate deviceIds: [NSNumber], fromJID: XMPPJID, incomingElement: DDXMLElement) {
        //print("deviceListUpdate: \(fromJID) \(deviceIds)")
    }
    
    public func omemo(omemo: OMEMOModule, failedToFetchDeviceIdsForJID fromJID: XMPPJID, errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        
    }
    
    public func omemo(omemo: OMEMOModule, publishedBundle bundle: OMEMOBundle, responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        //print("publishedBundle: \(responseIq) \(outgoingIq)")
    }
    
    public func omemo(omemo: OMEMOModule, failedToPublishBundle bundle: OMEMOBundle, errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        //print("failedToPublishBundle: \(errorIq) \(outgoingIq)")
    }
    
    public func omemo(omemo: OMEMOModule, fetchedBundle bundle: OMEMOBundle, fromJID: XMPPJID, responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        
        if (self.isOurJID(fromJID) && bundle.deviceId == self.signalEncryptionManager.registrationId) {
            //We fetched our own bundle
            if let ourDatabaseBundle = self.fetchMyBundle() {
                //This bundle doesn't have the correct identity key. Something has gone wrong and we should republish
                if !ourDatabaseBundle.identityKey.isEqualToData(bundle.identityKey) {
                    omemo.publishBundle(ourDatabaseBundle, elementId: nil)
                }
            }
            return;
        }
        
        dispatch_async(self.workQueue) {
            let elementId = outgoingIq.elementID()
            if (bundle.preKeys.count == 0) {
                self.callAndRemoveOutstandingBundleBlock(elementId, success: false)
                return
            }
            //Create incoming bundle from OMEMOBundle
            let innerBundle = OTROMEMOBundle(deviceId: bundle.deviceId, publicIdentityKey: bundle.identityKey, signedPublicPreKey: bundle.signedPreKey.publicKey, signedPreKeyId: bundle.signedPreKey.preKeyId, signedPreKeySignature: bundle.signedPreKey.signature)
            //Select random pre key to use
            let index = Int(arc4random_uniform(UInt32(bundle.preKeys.count)))
            let preKey = bundle.preKeys[index]
            let incomingBundle = OTROMEMOBundleIncoming(bundle: innerBundle, preKeyId: preKey.preKeyId, preKeyData: preKey.publicKey)
            //Consume the incoming bundle. This goes through signal and should hit the storage delegate. So we don't need to store ourselves here.
            self.signalEncryptionManager.consumeIncomingBundle(fromJID.bare(), bundle: incomingBundle)
            self.callAndRemoveOutstandingBundleBlock(elementId, success: true)
        }
        
    }
    public func omemo(omemo: OMEMOModule, failedToFetchBundleForDeviceId deviceId: gl_uint32_t, fromJID: XMPPJID, errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        
        dispatch_async(self.workQueue) {
            let elementId = outgoingIq.elementID()
            self.callAndRemoveOutstandingBundleBlock(elementId, success: false)
        }
    }
    
    public func omemo(omemo: OMEMOModule, receivedKeyData keyData: [OMEMOKeyData], iv: NSData, senderDeviceId: gl_uint32_t, fromJID: XMPPJID, payload: NSData?, message: XMPPMessage) {
        let rid = self.signalEncryptionManager.registrationId
        
        var ourKeyData: NSData? = nil
        for key in keyData {
            if key.deviceId == rid {
                ourKeyData = key.data
            }
        }
        guard let ourEncryptedKeyData = ourKeyData, let encryptedPayload = payload else {
            return
        }
        do {
            let unencryptedKeyData = try self.signalEncryptionManager.decryptFromAddress(ourEncryptedKeyData, name: fromJID.bare(), deviceId: senderDeviceId)
            let aesGcmBlockLength = 16
            let keyData = unencryptedKeyData.subdataWithRange(NSMakeRange(0, unencryptedKeyData.length - aesGcmBlockLength))
            let tag = unencryptedKeyData.subdataWithRange(NSMakeRange(unencryptedKeyData.length, aesGcmBlockLength))
            
            guard let messageBody = try OTRSignalEncryptionHelper.decryptData(encryptedPayload, key: keyData, iv: iv, authTag: tag) else {
                return
            }
            let messageString = String(data: messageBody, encoding: NSUTF8StringEncoding)
            self.databaseConnection.readWriteWithBlock({ (transaction) in
                // TODO: check if it's our jid and handle as an outgoing message from another device
                guard let buddy = OTRBuddy.fetchBuddyWithUsername(fromJID.bare(), withAccountUniqueId: self.accountYapKey, transaction: transaction) else {
                    return
                }
                let databaseMessage = OTRMessage()
                databaseMessage.incoming = true
                databaseMessage.text = messageString
                databaseMessage.buddyUniqueId = buddy.uniqueId
                databaseMessage.transportedSecurely = true
                databaseMessage.messageId = message.elementID()
                
                databaseMessage.saveWithTransaction(transaction)
            })
        } catch {
            return
        }
        
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
        //Convert from devices array to NSNumber array.
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
