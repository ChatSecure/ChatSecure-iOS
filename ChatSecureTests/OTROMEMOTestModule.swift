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
        //After authentication fake receiving devices from other buddy
        self.omemoStorage.storeDeviceIds([NSNumber(unsignedInt: device!)], forJID: otherJID)
        
    }
}
