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
@objc open class OTROMEMOSignalCoordinator: NSObject {
    
    open let signalEncryptionManager:OTRAccountSignalEncryptionManager
    open let omemoStorageManager:OTROMEMOStorageManager
    open let accountYapKey:String
    open let databaseConnection:YapDatabaseConnection
    open weak var omemoModule:OMEMOModule?
    open weak var omemoModuleQueue:DispatchQueue?
    open var callbackQueue:DispatchQueue
    open let workQueue:DispatchQueue
    fileprivate var myJID:XMPPJID? {
        get {
            return omemoModule?.xmppStream.myJID
        }
    }
    let preKeyCount:UInt = 100
    fileprivate var outstandingXMPPStanzaResponseBlocks:[String: (Bool) -> Void]
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
        self.outstandingXMPPStanzaResponseBlocks = [:]
        self.callbackQueue = DispatchQueue(label: "OTROMEMOSignalCoordinator-callback", attributes: [])
        self.workQueue = DispatchQueue(label: "OTROMEMOSignalCoordinator-work", attributes: [])
    }
    
    /**
     Checks that a jid matches our own JID using XMPPJIDCompareBare
     */
    fileprivate func isOurJID(_ jid:XMPPJID) -> Bool {
        guard let ourJID = self.myJID else {
            return false;
        }
        
        return jid.isEqual(to: ourJID, options: XMPPJIDCompareBare)
    }
    
    /** Always call on internal work queue */
    fileprivate func callAndRemoveOutstandingBundleBlock(_ elementId:String,success:Bool) {
        
        guard let outstandingBlock = self.outstandingXMPPStanzaResponseBlocks[elementId] else {
            return
        }
        outstandingBlock(success)
        self.outstandingXMPPStanzaResponseBlocks.removeValue(forKey: elementId)
    }
    
    /** 
     This must be called before sending every message. It ensures that for every device there is a session and if not the bundles are fetched.
     
     - parameter buddyYapKey: The yap key for the buddy to check
     - parameter completion: The completion closure called on callbackQueue. If it successfully was able to fetch all the bundles or if it wasn't necessary. If there were no devices for this buddy it will also return flase
     */
    open func prepareSessionForBuddy(_ buddyYapKey:String, completion:@escaping (Bool) -> Void) {
        self.prepareSession(buddyYapKey, yapCollection: OTRBuddy.collection(), completion: completion)
    }
    
    /**
     This must be called before sending every message. It ensures that for every device there is a session and if not the bundles are fetched.
     
     - parameter yapKey: The yap key for the buddy or account to check
     - parameter yapCollection: The yap key for the buddy or account to check
     - parameter completion: The completion closure called on callbackQueue. If it successfully was able to fetch all the bundles or if it wasn't necessary. If there were no devices for this buddy it will also return flase
     */
    open func prepareSession(_ yapKey:String, yapCollection:String, completion:@escaping (Bool) -> Void) {
        var devices:[OTROMEMODevice]? = nil
        var user:String? = nil
        
        //Get all the devices ID's for this buddy as well as their username for use with signal and XMPPFramework.
        self.databaseConnection.read { (transaction) in
            devices = OTROMEMODevice.allDevices(forParentKey: yapKey, collection: yapCollection, transaction: transaction)
            user = self.fetchUsername(yapKey, yapCollection: yapCollection, transaction: transaction)
        }
        
        guard let devs = devices, let username = user else {
            self.callbackQueue.async(execute: {
                completion(false)
            })
            return
        }
        
        var finalSuccess = true
        self.workQueue.async { [weak self] in
            guard let strongself = self else {
                return
            }
            
            let group = DispatchGroup()
            //For each device Check if we have a session. If not then we need to fetch it from their XMPP server.
            for device in devs where device.deviceId.uint32Value != self?.signalEncryptionManager.registrationId {
                if !strongself.signalEncryptionManager.sessionRecordExistsForUsername(username, deviceId: device.deviceId.int32Value) || device.publicIdentityKeyData == nil {
                    //No session for this buddy and device combo. We need to fetch the bundle.
                    //No public idenitty key data. We don't have enough information (for the user and UI) to encrypt this message.
                    
                    let elementId = UUID().uuidString
                    
                    group.enter()
                    // Hold on to a closure so that when we get the call back from OMEMOModule we can call this closure.
                    strongself.outstandingXMPPStanzaResponseBlocks[elementId] = { success in
                        if (!success) {
                            finalSuccess = false
                        }
                        
                        group.leave()
                    }
                    //Fetch the bundle
                    strongself.omemoModule?.fetchBundle(forDeviceId: device.deviceId.uint32Value, jid: XMPPJID(string:username), elementId: elementId)
                }
            }
            
            if let cQueue = self?.callbackQueue {
                group.notify(queue: cQueue) {
                    completion(finalSuccess)
                }

            }
        }
    }
    
    fileprivate func fetchUsername(_ yapKey:String, yapCollection:String, transaction:YapDatabaseReadTransaction) -> String? {
        if let object = transaction.object(forKey: yapKey, inCollection: yapCollection) {
            if object is OTRAccount {
                return (object as AnyObject).username
            } else if object is OTRBuddy {
                return (object as AnyObject).username
            }
        }
        return nil
    }
    
    /**
     Check if we have valid sessions with our other devices and if not fetch their bundles and start sessions.
     */
    func prepareSessionWithOurDevices(_ completion:@escaping (_ success:Bool) -> Void) {
        self.prepareSession(self.accountYapKey, yapCollection: OTRAccount.collection(), completion: completion)
    }
    
    fileprivate func encryptPayloadWithSignalForDevice(_ device:OTROMEMODevice, payload:Data) throws -> OMEMOKeyData? {
        var user:String? = nil
        self.databaseConnection.read({ (transaction) in
            user = self.fetchUsername(device.parentKey, yapCollection: device.parentCollection, transaction: transaction)
        })
        if let username = user {
            let encryptedKeyData = try self.signalEncryptionManager.encryptToAddress(payload, name: username, deviceId: device.deviceId.uint32Value)
            var isPreKey = false
            if (encryptedKeyData.type == .preKeyMessage) {
                isPreKey = true
            }
            return OMEMOKeyData(deviceId: device.deviceId.uint32Value, data: encryptedKeyData.data, isPreKey: isPreKey)
        }
        return nil
    }
    
    /**
     Gathers necessary information to encrypt a message to the buddy and all this accounts devices that are trusted. Then sends the payload via OMEMOModule
     
     - parameter messageBody: The boddy of the message
     - parameter buddyYapKey: The unique buddy yap key. Used for looking up the username and devices 
     - parameter messageId: The preffered XMPP element Id to be used.
     - parameter completion: The completion block is called after all the necessary omemo preperation has completed and sendKeyData:iv:toJID:payload:elementId: is invoked
     */
    open func encryptAndSendMessage(_ messageBody:String, buddyYapKey:String, messageId:String?, completion:@escaping (Bool,NSError?) -> Void) {
        // Gather bundles for buddy and account here
        let group = DispatchGroup()
        
        let prepareCompletion = { (success:Bool) in
            group.leave()
        }
        
        group.enter()
        group.enter()
        self.prepareSessionForBuddy(buddyYapKey, completion: prepareCompletion)
        self.prepareSessionWithOurDevices(prepareCompletion)
        //Even if something went wrong fetching bundles we should push ahead. We may have sessions that can be used.
        
        group.notify(queue: self.workQueue) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            //Strong self work here
            var bud:OTRBuddy? = nil
            strongSelf.databaseConnection.read { (transaction) in
                bud = OTRBuddy.fetchObject(withUniqueID: buddyYapKey, transaction: transaction)
            }
            
            guard let ivData = OTRSignalEncryptionHelper.generateIV(), let keyData = OTRSignalEncryptionHelper.generateSymmetricKey(), let messageBodyData = messageBody.data(using: String.Encoding.utf8) , let buddy = bud else {
                return
            }
            do {
                //Create the encrypted payload
                let payload = try OTRSignalEncryptionHelper.encryptData(messageBodyData, key: keyData, iv: ivData)
                
                
                // this does the signal encryption. If we fail it doesn't matter here. We end up trying the next device and fail later if no devices worked.
                let encryptClosure:(OTROMEMODevice) -> (OMEMOKeyData?) = { device in
                    do {
                        return try strongSelf.encryptPayloadWithSignalForDevice(device, payload: keyData as Data)
                    } catch {
                        return nil
                    }
                }
                
                /**
                 1. Get all devices for this buddy.
                 2. Filter only devices that are trusted.
                 3. encrypt to those devices.
                 4. Remove optional values
                */
                let buddyKeyDataArray = strongSelf.omemoStorageManager.getDevicesForParentYapKey(buddy.uniqueId, yapCollection: type(of: buddy).collection(), trusted: true).map(encryptClosure).flatMap{ $0 }
                
                // Stop here if we were not able to encrypt to any of the buddies
                if (buddyKeyDataArray.count == 0) {
                    strongSelf.callbackQueue.async(execute: {
                        let error = NSError.chatSecureError(OTROMEMOError.noDevicesForBuddy, userInfo: nil)
                        completion(false,error)
                    })
                    return
                }
                
                /**
                 1. Get all devices for this this account.
                 2. Filter only devices that are trusted and not ourselves.
                 3. encrypt to those devices.
                 4. Remove optional values
                 */
                let ourDevicesKeyData = strongSelf.omemoStorageManager.getDevicesForOurAccount(true).filter({ (device) -> Bool in
                    return device.deviceId.uint32Value != strongSelf.signalEncryptionManager.registrationId
                }).map(encryptClosure).flatMap{ $0 }
                
                // Combine teh two arrays for all key data
                let keyDataArray = ourDevicesKeyData + buddyKeyDataArray
                
                //Make sure we have encrypted the symetric key to someone
                if (keyDataArray.count > 0) {
                    guard let payloadData = payload?.data, let authTag = payload?.authTag else {
                        return
                    }
                    let finalPayload = NSMutableData()
                    finalPayload.append(payloadData)
                    finalPayload.append(authTag)
                    strongSelf.omemoModule?.sendKeyData(keyDataArray, iv: ivData, to: XMPPJID(string: buddy.username), payload: finalPayload as Data, elementId: messageId)
                    strongSelf.callbackQueue.async(execute: {
                        completion(true,nil)
                    })
                    return
                } else {
                    strongSelf.callbackQueue.async(execute: {
                        let error = NSError.chatSecureError(OTROMEMOError.noDevices, userInfo: nil)
                        completion(false,error)
                    })
                    return
                }
            } catch let err as NSError {
                //This should only happen if we had an error encrypting the payload
                strongSelf.callbackQueue.async(execute: {
                    completion(false,err)
                })
                return
            }
            
        }
    }
    
    /**
     Remove a device from the yap store and from the XMPP server.
     
     - parameter deviceId: The OMEMO device id
    */
    open func removeDevice(_ devices:[OTROMEMODevice], completion:@escaping ((Bool) -> Void)) {
        
        self.workQueue.async { [weak self] in
            
            guard let accountKey = self?.accountYapKey else {
                completion(false)
                return
            }
            //Array with tuple of username and the device
            //Needed to avoid nesting yap transactions
            var usernameDeviceArray = [(String,OTROMEMODevice)]()
            self?.databaseConnection.readWrite({ (transaction) in
                devices.forEach({ (device) in
                    
                    // Get the username if buddy or account. Could possibly be extracted into a extension or protocol
                    let extractUsername:(AnyObject?) -> String? = { object in
                        switch object {
                        case let buddy as OTRBuddy:
                            return buddy.username
                        case let account as OTRAccount:
                            return account.username
                        default: return nil
                        }
                    }
                    
                    //Need the parent object to get the username
                    let buddyOrAccount = transaction.object(forKey: device.parentKey, inCollection: device.parentCollection)
                    
                    
                    if let username = extractUsername(buddyOrAccount as AnyObject?) {
                        usernameDeviceArray.append((username,device))
                    }
                    device.remove(with: transaction)
                })
            })
            
            //For each username device pair remove the underlying signal session
            usernameDeviceArray.forEach({ (username,device) in
                _ = self?.signalEncryptionManager.removeSessionRecordForUsername(username, deviceId: device.deviceId.int32Value)
            })
            
            
            let remoteDevicesToRemove = devices.filter({ (device) -> Bool in
                // Can only remove devices that belong to this account from the remote server.
                return device.parentKey == accountKey && device.parentCollection == OTRAccount.collection()
            })
            
            if( remoteDevicesToRemove.count > 0 ) {
                let elementId = UUID().uuidString
                let deviceIds = remoteDevicesToRemove.map({ (device) -> NSNumber in
                    return device.deviceId
                })
                self?.outstandingXMPPStanzaResponseBlocks[elementId] = { success in
                    completion(success)
                }
                self?.omemoModule?.removeDeviceIds(deviceIds, elementId: elementId)
            } else {
                completion(true)
            }
        }
    }
    
    open func processKeyData(_ keyData: [OMEMOKeyData], iv: Data, senderDeviceId: UInt32, fromJID: XMPPJID, payload: Data?, message: XMPPMessage) {
        let aesGcmBlockLength = 16
        guard let encryptedPayload = payload, encryptedPayload.count > 0 else {
            return
        }
        
        let rid = self.signalEncryptionManager.registrationId
        
        //Could have multiple matching device id. This is extremely rare but possible that the sender has another device that collides with our device id.
        var unencryptedKeyData: Data?
        for key in keyData {
            if key.deviceId == rid {
                let keyData = key.data
                do {
                    unencryptedKeyData = try self.signalEncryptionManager.decryptFromAddress(keyData, name: fromJID.bare(), deviceId: senderDeviceId)
                    // have successfully decripted the AES key. We should break and use it to decrypt the payload
                    break
                } catch {
                    return
                }
            }
        }
        
        guard var aesKey = unencryptedKeyData else {
            return
        }
        var authTag: Data?
        
        // Treat >=32 bytes OMEMO 'keys' as containing the auth tag.
        // https://github.com/ChatSecure/ChatSecure-iOS/issues/647
        if (aesKey.count >= aesGcmBlockLength * 2) {
            
            authTag = aesKey.subdata(in: aesGcmBlockLength..<aesKey.count)
            aesKey = aesKey.subdata(in: 0..<aesGcmBlockLength)
        }
        
        var tmpBody: Data?
        // If there's already an auth tag, that means the payload
        // doesn't contain the auth tag.
        if authTag != nil { // omemo namespace
            tmpBody = encryptedPayload
        } else { // 'siacs' namespace fallback
            
            tmpBody = encryptedPayload.subdata(in: 0..<encryptedPayload.count - aesGcmBlockLength)
            authTag = encryptedPayload.subdata(in: encryptedPayload.count - aesGcmBlockLength..<encryptedPayload.count)
        }
        guard let tag = authTag, let encryptedBody = tmpBody else {
            return
        }
        
        do {
            guard let messageBody = try OTRSignalEncryptionHelper.decryptData(encryptedBody, key: aesKey, iv: iv, authTag: tag) else {
                return
            }
            let messageString = String(data: messageBody, encoding: String.Encoding.utf8)
            var databaseMessage:OTRBaseMessage = OTRIncomingMessage()
            guard let ourJID = self.myJID else {
                return
            }
            var relatedBuddyUsername = fromJID.bare() as String!
            var innerMessage = message
            if (message.isTrustedMessageCarbon(forMyJID: ourJID)) {
                //This came from another of our devices this is really going to be an outgoing message
                innerMessage = message.messageCarbonForwarded()
                if (message.isReceivedMessageCarbon()) {
                    relatedBuddyUsername = innerMessage.from().bare() as String
                } else {
                    relatedBuddyUsername = innerMessage.to().bare() as String
                    let outgoingMessage = OTROutgoingMessage()
                    outgoingMessage?.dateSent = Date()
                    databaseMessage = outgoingMessage!
                }
            }
            
            self.databaseConnection.asyncReadWrite({ (transaction) in
                
                guard let buddyUsernmae = relatedBuddyUsername, let buddy = OTRBuddy.fetch(withUsername: buddyUsernmae, withAccountUniqueId: self.accountYapKey, transaction: transaction) else {
                    return
                }
                databaseMessage.text = messageString
                databaseMessage.buddyUniqueId = buddy.uniqueId
                
                let deviceNumber = NSNumber(value: senderDeviceId as UInt32)
                let deviceYapKey = OTROMEMODevice.yapKey(withDeviceId: deviceNumber, parentKey: buddy.uniqueId, parentCollection: OTRBuddy.collection())
                databaseMessage.messageSecurityInfo = OTRMessageEncryptionInfo.init(omemoDevice: deviceYapKey, collection: OTROMEMODevice.collection())!
                if let id = innerMessage.elementID() {
                    databaseMessage.messageId = id
                }
                
                databaseMessage.save(with: transaction)
                
                // Should we be using the date of the xmpp message?
                buddy.lastMessageId = databaseMessage.uniqueId
                buddy.save(with: transaction)
                
                //Update device last received message
                guard let device = OTROMEMODevice.fetchObject(withUniqueID: deviceYapKey, transaction: transaction) else {
                    return
                }
                let newDevice = OTROMEMODevice(deviceId: device.deviceId, trustLevel: device.trustLevel, parentKey: device.parentKey, parentCollection: device.parentCollection, publicIdentityKeyData: device.publicIdentityKeyData, lastSeenDate: Date())
                newDevice.save(with: transaction)
                
                // Send delivery receipt
                guard let account = OTRAccount.fetchObject(withUniqueID: buddy.accountUniqueId, transaction: transaction) else {
                    return
                }
                guard let protocolManager = OTRProtocolManager.sharedInstance().protocol(for: account) as? OTRXMPPManager else {
                    return
                }
                
                if let incomingMessage = databaseMessage as? OTRIncomingMessage {
                    protocolManager.sendDeliveryReceipt(for: incomingMessage)
                }
                
                }, completionBlock: {
                    if let _ = databaseMessage.text {
                        if let messageCopy = databaseMessage.copy() as? OTRIncomingMessage {
                            DispatchQueue.main.async(execute: {
                                UIApplication.shared.showLocalNotification(messageCopy)
                            })
                        }
                    }
            })
            // Display local notification
            
        } catch {
            return
        }

    }
}

extension OTROMEMOSignalCoordinator: OMEMOModuleDelegate {
    
    public func omemo(_ omemo: OMEMOModule, publishedDeviceIds deviceIds: [NSNumber], responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        //print("publishedDeviceIds: \(responseIq)")
    }
    
    public func omemo(_ omemo: OMEMOModule, failedToPublishDeviceIds deviceIds: [NSNumber], errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        //print("failedToPublishDeviceIds: \(errorIq)")
    }
    
    public func omemo(_ omemo: OMEMOModule, deviceListUpdate deviceIds: [NSNumber], from fromJID: XMPPJID, incomingElement: XMPPElement) {
        //print("deviceListUpdate: \(fromJID) \(deviceIds)")
        self.workQueue.async { [weak self] in
            if let eid = incomingElement.elementID() {
                self?.callAndRemoveOutstandingBundleBlock(eid, success: true)
            }
        }
    }
    
    public func omemo(_ omemo: OMEMOModule, failedToFetchDeviceIdsFor fromJID: XMPPJID, errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        
    }
    
    public func omemo(_ omemo: OMEMOModule, publishedBundle bundle: OMEMOBundle, responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        //print("publishedBundle: \(responseIq) \(outgoingIq)")
    }
    
    public func omemo(_ omemo: OMEMOModule, failedToPublishBundle bundle: OMEMOBundle, errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        //print("failedToPublishBundle: \(errorIq) \(outgoingIq)")
    }
    
    public func omemo(_ omemo: OMEMOModule, fetchedBundle bundle: OMEMOBundle, from fromJID: XMPPJID, responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        
        if (self.isOurJID(fromJID) && bundle.deviceId == self.signalEncryptionManager.registrationId) {
            //DDLogVerbose("fetchedOurOwnBundle: \(responseIq) \(outgoingIq)")

            //We fetched our own bundle
            if let ourDatabaseBundle = self.fetchMyBundle() {
                //This bundle doesn't have the correct identity key. Something has gone wrong and we should republish
                if ourDatabaseBundle.identityKey != bundle.identityKey {
                    //DDLogError("Bundle identityKeys do not match! \(ourDatabaseBundle.identityKey) vs \(bundle.identityKey)")
                    omemo.publishBundle(ourDatabaseBundle, elementId: nil)
                }
            }
            return;
        }
        
        self.workQueue.async { [weak self] in
            let elementId = outgoingIq.elementID()
            if (bundle.preKeys.count == 0) {
                self?.callAndRemoveOutstandingBundleBlock(elementId!, success: false)
                return
            }
            //Create incoming bundle from OMEMOBundle
            let innerBundle = OTROMEMOBundle(deviceId: bundle.deviceId, publicIdentityKey: bundle.identityKey, signedPublicPreKey: bundle.signedPreKey.publicKey, signedPreKeyId: bundle.signedPreKey.preKeyId, signedPreKeySignature: bundle.signedPreKey.signature)
            //Select random pre key to use
            let index = Int(arc4random_uniform(UInt32(bundle.preKeys.count)))
            let preKey = bundle.preKeys[index]
            let incomingBundle = OTROMEMOBundleIncoming(bundle: innerBundle, preKeyId: preKey.preKeyId, preKeyData: preKey.publicKey)
            //Consume the incoming bundle. This goes through signal and should hit the storage delegate. So we don't need to store ourselves here.
            var result = false
            do {
                try self?.signalEncryptionManager.consumeIncomingBundle(fromJID.bare(), bundle: incomingBundle)
                result = true
            } catch let err as NSError {
                #if DEBUG
                    NSLog("Error consuming incoming bundle %@ %@", err, responseIq.prettyXMLString())
                #endif
            }
            self?.callAndRemoveOutstandingBundleBlock(elementId!, success: result)
        }
        
    }
    public func omemo(_ omemo: OMEMOModule, failedToFetchBundleForDeviceId deviceId: UInt32, from fromJID: XMPPJID, errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        
        self.workQueue.async { [weak self] in
            let elementId = outgoingIq.elementID()
            self?.callAndRemoveOutstandingBundleBlock(elementId!, success: false)
        }
    }
    
    public func omemo(_ omemo: OMEMOModule, removedBundleId bundleId: UInt32, responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        
    }
    
    public func omemo(_ omemo: OMEMOModule, failedToRemoveBundleId bundleId: UInt32, errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        
    }
    
    public func omemo(_ omemo: OMEMOModule, failedToRemoveDeviceIds deviceIds: [NSNumber], errorIq: XMPPIQ?, elementId: String?) {
        self.workQueue.async { [weak self] in
            if let eid = elementId {
                self?.callAndRemoveOutstandingBundleBlock(eid, success: false)
            }
        }
    }
    
    public func omemo(_ omemo: OMEMOModule, receivedKeyData keyData: [OMEMOKeyData], iv: Data, senderDeviceId: UInt32, from fromJID: XMPPJID, payload: Data?, message: XMPPMessage) {
        self.processKeyData(keyData, iv: iv, senderDeviceId: senderDeviceId, fromJID: fromJID, payload: payload, message: message)
    }
}

extension OTROMEMOSignalCoordinator:OMEMOStorageDelegate {
    
    public func configure(withParent aParent: OMEMOModule, queue: DispatchQueue) -> Bool {
        self.omemoModule = aParent
        self.omemoModuleQueue = queue
        return true
    }
    
    public func storeDeviceIds(_ deviceIds: [NSNumber], for jid: XMPPJID) {
        
        let isOurDeviceList = self.isOurJID(jid)
        
        if (isOurDeviceList) {
            self.omemoStorageManager.storeOurDevices(deviceIds)
        } else {
            self.omemoStorageManager.storeBuddyDevices(deviceIds, buddyUsername: jid.bare())
        }
    }
    
    public func fetchDeviceIds(for jid: XMPPJID) -> [NSNumber] {
        var devices:[OTROMEMODevice]?
        if self.isOurJID(jid) {
            devices = self.omemoStorageManager.getDevicesForOurAccount(nil)
            
        } else {
            devices = self.omemoStorageManager.getDevicesForBuddy(jid.bare(), trusted:nil)
        }
        //Convert from devices array to NSNumber array.
        return (devices?.map({ (device) -> NSNumber in
            return device.deviceId
        })) ?? [NSNumber]()
        
    }

    //Always returns most complete bundle with correct count of prekeys
    public func fetchMyBundle() -> OMEMOBundle? {
        var _bundle: OTROMEMOBundleOutgoing? = nil
        
        do {
            _bundle = try signalEncryptionManager.storage.fetchOurExistingBundle()
            
        } catch let omemoError as OMEMOBundleError {
            switch omemoError {
            case .invalid:
                //DDLogError("Found invalid stored bundle!")
                // delete???
                break
            default:
                break
            }
        } catch let error {
            //DDLogError("Other error fetching bundle! \(error)")
        }
        let maxTries = 50
        var tries = 0
        while _bundle == nil && tries < maxTries {
            tries = tries + 1
            do {
                _bundle = try self.signalEncryptionManager.generateOutgoingBundle(self.preKeyCount)
            } catch let error {
                //DDLogError("Error generating bundle! Try #\(tries)/\(maxTries) \(error)")
            }
        }
        guard let bundle = _bundle else {
            //DDLogError("Could not fetch or generate valid bundle!")
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

    public func isSessionValid(_ jid: XMPPJID, deviceId: UInt32) -> Bool {
        return self.signalEncryptionManager.sessionRecordExistsForUsername(jid.bare(), deviceId: Int32(deviceId))
    }
}
