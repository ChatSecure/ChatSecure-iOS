//
//  OTROMEMOTestModule.swift
//  ChatSecure
//
//  Created by David Chiles on 10/7/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import XCTest
import XMPPFramework

class OTROMEMOTestModule: OMEMOModule {

    var otherUser:TestUser!
    var thisUser:TestUser!
    
    override var xmppStream:XMPPStream {
        get {
            let stream = XMPPStream()
            stream.myJID = XMPPJID.jidWithString(self.thisUser.account.username)
            return stream
        }
    }
    
    override func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        
        let bundle = otherUser.signalOMEMOCoordinator.fetchMyBundle()
        XCTAssertNotNil(bundle)
        let device = bundle?.deviceId
        XCTAssertNotNil(device)
        let otherJID = XMPPJID.jidWithString(otherUser.account.username)
        let ourJID = XMPPJID.jidWithString(thisUser.account.username)
        //After authentication fake receiving devices from other buddy
        self.omemoStorage.storeDeviceIds([NSNumber(unsignedInt: device!)], forJID: otherJID)
        self.omemoStorage.storeDeviceIds([NSNumber(unsignedInt: (thisUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId)!)], forJID: ourJID)
    }
    
    override func fetchBundleForDeviceId(deviceId: gl_uint32_t, jid: XMPPJID, elementId: String?) {
        dispatch_async(self.moduleQueue) { 
            if self.otherUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId == deviceId {
                let multicastDelegate = self.valueForKey("multicastDelegate")!
                let response = XMPPIQ(type: "get", to: nil, elementID: elementId, child: nil)
                let outgoing = XMPPIQ(type: "get", to: nil, elementID: elementId, child: nil)
                multicastDelegate.omemo!(self, fetchedBundle: self.otherUser.signalOMEMOCoordinator.fetchMyBundle()!, fromJID: jid, responseIq: response, outgoingIq: outgoing)
            }
        }
    }
    
    override func sendKeyData(keyData: [OMEMOKeyData], iv: NSData, toJID: XMPPJID, payload: NSData?, elementId: String?) {
        let dummyMessage = XMPPMessage()
        self.otherUser.signalOMEMOCoordinator.omemo(self, receivedKeyData: keyData, iv: iv, senderDeviceId: (thisUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId)!, fromJID: XMPPJID.jidWithString(thisUser.account.username), payload: payload, message: dummyMessage)
    }
}
