//
//  OTROMEMOBundle.swift
//  ChatSecure
//
//  Created by David Chiles on 7/29/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

public struct OTROMEMOBundle {
    let deviceId:UInt32
    let publicIdentityKey:Data
    let signedPublicPreKey:Data
    let signedPreKeyId:UInt32
    let signedPreKeySignature:Data
}

public struct OTROMEMOBundleOutgoing {
    let bundle:OTROMEMOBundle
    let preKeys:[UInt32:Data]
}

public struct OTROMEMOBundleIncoming {
    let bundle:OTROMEMOBundle
    let preKeyId:UInt32
    let preKeyData:Data
}
