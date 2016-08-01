//
//  OTROMEMOBundle.swift
//  ChatSecure
//
//  Created by David Chiles on 7/29/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit

public struct OTROMEMOBundle {
    let deviceId:UInt32
    let publicIdentityKey:NSData
    let signedPublicPreKey:NSData
    let signedPreKeyId:UInt32
    let signedPreKeySignature:NSData
    let preKeys:[UInt32:NSData]
}
