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

let kPepPrefix = "urn:xmpp:omemo:0"
let kPepDeviceList = kPepPrefix+":devicelist"
let kPepDeviceListNotify = kPepDeviceList+"+notify"
let kePepBundles = kPepPrefix+":bundles"


/** This is the glue between XMPP/OMEMO and Signal*/
@objc public class OTROMEMOSignalCoordinator: NSObject {
    
    public let signalEncryptionManager:OTRAccountSignalEncryptionManager
    public let accountYapKey:String
    public weak var omemoModule:OMEMOModule?
    let workQueue:dispatch_queue_t
    var xmppTracker:XMPPIDTracker?
    
    @objc public init(accountYapKey:String, databaseConnection:YapDatabaseConnection, omemoModule:OMEMOModule?) {
        self.signalEncryptionManager = OTRAccountSignalEncryptionManager(accountKey: accountYapKey,databaseConnection: databaseConnection)
        self.accountYapKey = accountYapKey
        self.omemoModule = omemoModule
        self.workQueue = dispatch_queue_create("OTROMEMOSignalCoordinator-work-queue", DISPATCH_QUEUE_SERIAL)
    }

}

extension OTROMEMOSignalCoordinator:OMEMODelegate {
    
    /**
     * In order to determine whether a given contact has devices that support OMEMO, the devicelist node in PEP is consulted. Devices MUST subscribe to 'urn:xmpp:omemo:0:devicelist' via PEP, so that they are informed whenever their contacts add a new device. They MUST cache the most up-to-date version of the devicelist.
     */
    public func omemo(omemo: OMEMOModule, deviceListUpdate deviceIds: [NSNumber], fromJID: XMPPJID, message: XMPPMessage) {
        //print("device List Update \(deviceIds) \(fromJID) \(message)")
        //print("\n")
    }
}

extension OTROMEMOSignalCoordinator:XMPPStreamDelegate {
    public func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        //TODO: Need to figure out when to do this. Especially on first connection when a device won't come down. When should we send one up
        //When do we need to explicity fetch and when do we depend on PEP to just send us stuff
//        let outgoingBundle = self.signalEncryptionManager.generateOutgoingBundle()
//        let deviceId = self.signalEncryptionManager.registrationId
//        let deviceNumber = NSNumber(unsignedInt: deviceId)
//        self.omemoModule?.publishDeviceIds([deviceNumber])
        //Fetch PEP because we don't know if it's there or not. And we don't know how long to wait for it to be auto-pushed to us
        //Should probably do this later and make sure the server supports PEP.
        if self.xmppTracker == nil {
            self.xmppTracker = XMPPIDTracker(stream: sender, dispatchQueue: self.workQueue)
        }
        
        let deviceGetIQ = XMPPIQ.omemo_iqfetchDevices(sender.myJID)
        dispatch_async(self.workQueue) { 
            
        }
        self.xmppTracker?.addElement(deviceGetIQ, block: { (object, info) in
            print("\(object)")
            }, timeout: 5.0)
        sender.sendElement(deviceGetIQ);
    }
    
    public func xmppStream(sender: XMPPStream!, didReceiveMessage message: XMPPMessage!) {
        guard let _ = message.elementForName("event", xmlns: XMLNS_PUBSUB_EVENT) else {
            return
        }
        if (sender.myJID.isEqualToJID(message.from(), options: XMPPJIDCompareBare)) {
            //This is our own PEP
            if var deviceList = message.omemo_deviceList() {
                let deviceNumber = NSNumber(unsignedInt: self.signalEncryptionManager.registrationId)
                if !deviceList.contains(deviceNumber) {
                    //Need to add device
                    deviceList.append(deviceNumber)
                    self.omemoModule?.publishDeviceIds(deviceList)
                }
            }
        } else {
            //This is someone elses PEP
        }
    }
}

extension OTROMEMOSignalCoordinator:XMPPCapabilitiesDelegate {
    public func myFeaturesForXMPPCapabilities(sender: XMPPCapabilities!) -> [AnyObject]!{
        
        return [kPepDeviceList,kPepDeviceListNotify]
    }
    
}
