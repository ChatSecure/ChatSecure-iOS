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
    
    /** Manually called after all the otherUser and thisUser are setup */
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
    
    /** When fetching a bundle for device and jid we return that device given to us in the other user struct*/
    override func fetchBundleForDeviceId(deviceId: gl_uint32_t, jid: XMPPJID, elementId: String?) {
        dispatch_async(self.moduleQueue) { 
            if self.otherUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId == deviceId {
                let multicastDelegate = self.valueForKey("multicastDelegate")!
                //Empty responses so not nil and have correct elementID.
                let response = XMPPIQ(type: "get", to: nil, elementID: elementId, child: nil)
                let outgoing = XMPPIQ(type: "get", to: nil, elementID: elementId, child: nil)
                multicastDelegate.omemo!(self, fetchedBundle: self.otherUser.signalOMEMOCoordinator.fetchMyBundle()!, fromJID: jid, responseIq: response, outgoingIq: outgoing)
                
            }
        }
    }
    
    /** When we send key data we automtically route that data to the other user to decrypto*/
    override func sendKeyData(keyData: [OMEMOKeyData], iv: NSData, toJID: XMPPJID, payload: NSData?, elementId: String?) {
        let dummyMessage = XMPPMessage(type: "chat", elementID: "1234")
        self.otherUser.signalOMEMOCoordinator.omemo(self, receivedKeyData: keyData, iv: iv, senderDeviceId: (thisUser.signalOMEMOCoordinator.fetchMyBundle()?.deviceId)!, fromJID: XMPPJID.jidWithString(thisUser.account.username), payload: payload, message: dummyMessage)
    }
    
    override func removeDeviceIds(deviceIds: [NSNumber], elementId: String?) {
        dispatch_async(self.moduleQueue) {
            let multicastDelegate = self.valueForKey("multicastDelegate")!
            let element = XMPPIQ(type: "resutl", to: self.xmppStream.myJID, elementID: elementId)
            multicastDelegate.omemo!(self, deviceListUpdate: [NSNumber](), fromJID:self.xmppStream.myJID, incomingElement:element)
        }
    }
}
