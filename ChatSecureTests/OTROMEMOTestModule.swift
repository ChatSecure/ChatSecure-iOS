//
//  OTROMEMOTestModule.swift
//  ChatSecure
//
//  Created by David Chiles on 10/7/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import XCTest
import XMPPFramework

protocol OTROMEMOTestModuleProtocol: class {
    func username() -> String
    func receiveKeyData(keyData: [OMEMOKeyData], iv: NSData, fromJID: XMPPJID, senderDeviceId: gl_uint32_t, payload: NSData?, elementId: String?)
    func bundle() -> OMEMOBundle
}

class OTROMEMOTestModule: OMEMOModule {

    weak var otherUser:OTROMEMOTestModuleProtocol?
    var thisUser:TestUser!
    
    override var xmppStream:XMPPStream {
        get {
            let stream = XMPPStream()
            stream.myJID = XMPPJID.jidWithString(self.thisUser.account.username)
            return stream
        }
    }
    
    /** Manually called after all the otherUser and thisUser are setup */
    override func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        
        let bundle = otherUser?.bundle()
        XCTAssertNotNil(bundle)
        let device = bundle?.deviceId
        XCTAssertNotNil(device)
        let otherJID = XMPPJID.jidWithString(otherUser?.username())
        let ourJID = XMPPJID.jidWithString(thisUser.account.username)
        //After authentication fake receiving devices from other buddy
        self.omemoStorage.storeDeviceIds([NSNumber(unsignedInt: device!)], forJID: otherJID)
        self.omemoStorage.storeDeviceIds([NSNumber(unsignedInt: (thisUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId)!)], forJID: ourJID)
    }
    
    /** When fetching a bundle for device and jid we return that device given to us in the other user struct*/
    override func fetchBundleForDeviceId(deviceId: gl_uint32_t, jid: XMPPJID, elementId: String?) {
        dispatch_async(self.moduleQueue) { 
            if self.otherUser?.bundle().deviceId == deviceId {
                let multicastDelegate = self.valueForKey("multicastDelegate")!
                //Empty responses so not nil and have correct elementID.
                let response = XMPPIQ(type: "get", to: nil, elementID: elementId, child: nil)
                let outgoing = XMPPIQ(type: "get", to: nil, elementID: elementId, child: nil)
                multicastDelegate.omemo!(self, fetchedBundle: self.otherUser!.bundle(), fromJID: jid, responseIq: response, outgoingIq: outgoing)
                
            }
        }
    }
    
    /** When we send key data we automtically route that data to the other user to decrypto*/
    override func sendKeyData(keyData: [OMEMOKeyData], iv: NSData, toJID: XMPPJID, payload: NSData?, elementId: String?) {
        
        self.otherUser?.receiveKeyData(keyData, iv: iv, fromJID: XMPPJID.jidWithString(thisUser.account.username), senderDeviceId:(thisUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId)!, payload: payload, elementId: elementId)
        //self.otherUser.signalOMEMOCoordinator.omemo(self, receivedKeyData: keyData, iv: iv, senderDeviceId: (thisUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId)!, fromJID: XMPPJID.jidWithString(thisUser.account.username), payload: payload, message: dummyMessage)
    }
    
    override func removeDeviceIds(deviceIds: [NSNumber], elementId: String?) {
        dispatch_async(self.moduleQueue) {
            let multicastDelegate = self.valueForKey("multicastDelegate")!
            let element = XMPPIQ(type: "resutl", to: self.xmppStream.myJID, elementID: elementId)
            multicastDelegate.omemo!(self, deviceListUpdate: [NSNumber](), fromJID:self.xmppStream.myJID, incomingElement:element)
        }
    }
}

extension OTROMEMOTestModule: OTROMEMOTestModuleProtocol {
    func username() -> String {
        return self.thisUser.account.username
    }
    
    func receiveKeyData(keyData: [OMEMOKeyData], iv: NSData, fromJID: XMPPJID, senderDeviceId:gl_uint32_t, payload: NSData?, elementId: String?) {
        let dummyMessage = XMPPMessage(type: "chat", elementID: "1234")
        self.thisUser.signalOMEMOCoordinator.omemo(self, receivedKeyData: keyData, iv: iv, senderDeviceId: senderDeviceId, fromJID: fromJID, payload: payload, message: dummyMessage)
    }
    
    func bundle() -> OMEMOBundle {
        return self.thisUser.signalOMEMOCoordinator.fetchMyBundle()!
    }
}
