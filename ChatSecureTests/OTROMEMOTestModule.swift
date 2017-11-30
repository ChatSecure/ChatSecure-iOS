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
    func receiveKeyData(_ keyData: [OMEMOKeyData], iv: Data, fromJID: XMPPJID, senderDeviceId: UInt32, payload: Data?, elementId: String?)
    func bundle() -> OMEMOBundle
}

class OTROMEMOTestModule: OMEMOModule {

    weak var otherUser:OTROMEMOTestModuleProtocol?
    var thisUser:TestUser!
    
    override var xmppStream:XMPPStream {
        get {
            let stream = XMPPStream()
            stream.myJID = XMPPJID(string:self.thisUser.account.username)
            return stream
        }
    }
    
    /** Manually called after all the otherUser and thisUser are setup */
    override func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        let bundle = otherUser?.bundle()
        XCTAssertNotNil(bundle)
        let device = bundle?.deviceId
        XCTAssertNotNil(device)
        let otherUserStr = otherUser!.username()
        let otherJID = XMPPJID(string:otherUserStr)!
        let ourJID = XMPPJID(string:thisUser.account.username)!
        //After authentication fake receiving devices from other buddy
        self.omemoStorage.storeDeviceIds([NSNumber(value: device! as UInt32)], for: otherJID)
        self.omemoStorage.storeDeviceIds([NSNumber(value: (thisUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId)!)], for: ourJID)
    }
    
    /** When fetching a bundle for device and jid we return that device given to us in the other user struct*/
    override func fetchBundle(forDeviceId deviceId: UInt32, jid: XMPPJID, elementId: String?) {
        self.moduleQueue.async { 
            if self.otherUser?.bundle().deviceId == deviceId {
                let multicastDelegate = self.value(forKey: "multicastDelegate")!
                //Empty responses so not nil and have correct elementID.
                let response = XMPPIQ(type: "get", to: nil, elementID: elementId, child: nil)
                let outgoing = XMPPIQ(type: "get", to: nil, elementID: elementId, child: nil)
                (multicastDelegate as AnyObject).omemo!(self, fetchedBundle: self.otherUser!.bundle(), from: jid, responseIq: response, outgoingIq: outgoing)
                
            }
        }
    }
    
    /** When we send key data we automtically route that data to the other user to decrypto*/
    override func sendKeyData(_ keyData: [OMEMOKeyData], iv: Data, to toJID: XMPPJID, payload: Data?, elementId: String?) {
        
        self.otherUser?.receiveKeyData(keyData, iv: iv, fromJID: XMPPJID(string:thisUser.account.username)!, senderDeviceId:(thisUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId)!, payload: payload, elementId: elementId)
        //self.otherUser.signalOMEMOCoordinator.omemo(self, receivedKeyData: keyData, iv: iv, senderDeviceId: (thisUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId)!, fromJID: XMPPJID.jidWithString(thisUser.account.username), payload: payload, message: dummyMessage)
    }
    
    override func removeDeviceIds(_ deviceIds: [NSNumber], elementId: String?) {
        self.moduleQueue.async {
            let multicastDelegate = self.value(forKey: "multicastDelegate")!
            let element = XMPPIQ(type: "result", to: self.xmppStream.myJID, elementID: elementId)
            (multicastDelegate as AnyObject).omemo!(self, deviceListUpdate: [NSNumber](), from:self.xmppStream.myJID!, incomingElement:element)
        }
    }
}

extension OTROMEMOTestModule: OTROMEMOTestModuleProtocol {
    func username() -> String {
        return self.thisUser.account.username
    }
    
    func receiveKeyData(_ keyData: [OMEMOKeyData], iv: Data, fromJID: XMPPJID, senderDeviceId:UInt32, payload: Data?, elementId: String?) {
        let dummyMessage = XMPPMessage(type: "chat", elementID: "1234")
        dummyMessage.addAttribute(withName: "from", stringValue: fromJID.full)
        dummyMessage.addAttribute(withName: "to", stringValue: username())
        self.thisUser.signalOMEMOCoordinator.omemo(self, receivedKeyData: keyData, iv: iv, senderDeviceId: senderDeviceId, from: fromJID, payload: payload, message: dummyMessage)
    }
    
    func bundle() -> OMEMOBundle {
        return self.thisUser.signalOMEMOCoordinator.fetchMyBundle()!
    }
}
