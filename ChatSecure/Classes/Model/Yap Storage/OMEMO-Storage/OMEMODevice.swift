//
//  OMEMODevice.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 2/20/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation

extension OMEMODevice {
    
    /// Generally either an OTRXMPPAccount or OTRXMPPBuddy
    @objc public func parent(with transaction: YapDatabaseReadTransaction) -> Any? {
        return transaction.object(forKey: parentKey, inCollection: parentCollection)
    }
    
    /// Checks if any of the devices are untrusted/new
    @objc public static func filterNewDevices(_ devices: [OMEMODevice], transaction: YapDatabaseReadTransaction) -> [OMEMODevice] {
        let untrusted = devices.filter { (device) -> Bool in
            device.trustLevel == .untrustedNew
        }
        return untrusted
    }
}
