//
//  OMEMODeviceFingerprintCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 10/14/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import XLForm
import OTRAssets
import XMPPFramework
import FormatterKit
import OTRKit

private extension String {
    //http://stackoverflow.com/a/34454633/805882
    func splitEvery(_ n: Int) -> [String] {
        var result: [String] = []
        let chars = Array(self)
        for index in stride(from: 0, to: chars.count, by: n) {
            result.append(String(chars[index..<min(index+n, chars.count)]))
        }
        return result
    }
}

extension NSData {
    /// hex, split every 8 bytes by a space
    @objc public func humanReadableFingerprint() -> String {
        return (self as NSData).xmpp_hexStringValue.splitEvery(8).joined(separator: " ")
    }
}

extension XLFormBaseCell {
    
    @objc public class func defaultRowDescriptorType() -> String {
        let type = NSStringFromClass(self)
        return type
    }
    
    @objc public class func registerCellClass(_ forType: String) {
        let bundle = OTRAssets.resourcesBundle
        let path = bundle.bundlePath
        guard let bundleName = (path as NSString?)?.lastPathComponent else {
            return
        }
        let className = bundleName + "/" + NSStringFromClass(self)
        XLFormViewController.cellClassesForRowDescriptorTypes().setObject(className, forKey: forType as NSString)
    }
}

@objc(OMEMODeviceFingerprintCell)
open class OMEMODeviceFingerprintCell: XLFormBaseCell {
    
    @IBOutlet weak var fingerprintLabel: UILabel!
    @IBOutlet weak var trustSwitch: UISwitch!
    @IBOutlet weak var lastSeenLabel: UILabel!
    @IBOutlet weak var trustLevelLabel: UILabel!
    
    fileprivate static let intervalFormatter = TTTTimeIntervalFormatter()
    
    open override class func formDescriptorCellHeight(for rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 90
    }
    
    open override func update() {
        super.update()
        if let device = rowDescriptor.value as? OMEMODevice {
            updateCellFromDevice(device)
        }
        if let fingerprint = rowDescriptor.value as? OTRFingerprint {
            updateCellFromFingerprint(fingerprint)
        }
        let enabled = !rowDescriptor.isDisabled()
        trustSwitch.isEnabled = enabled
        fingerprintLabel.isEnabled = enabled
        lastSeenLabel.isEnabled = enabled
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if let device = rowDescriptor.value as? OMEMODevice {
            switchValueWithDevice(device)
        }
        if let fingerprint = rowDescriptor.value as? OTRFingerprint {
            switchValueWithFingerprint(fingerprint)
        }
    }
    
    fileprivate func updateCellFromDevice(_ device: OMEMODevice) {
        let trusted = device.isTrusted()
        trustSwitch.isOn = trusted
        
        // we've already filtered out devices w/o public keys
        // so publicIdentityKeyData should never be nil
        let fingerprint = device.humanReadableFingerprint
        
        fingerprintLabel.text = fingerprint
        let interval = -Date().timeIntervalSince(device.lastSeenDate)
        let since = type(of: self).intervalFormatter.string(forTimeInterval: interval)
        let lastSeen = "OMEMO: " + since!
        lastSeenLabel.text = lastSeen
        if (device.trustLevel == .trustedTofu) {
            trustLevelLabel.text = "TOFU"
        } else if (device.trustLevel == .trustedUser) {
            trustLevelLabel.text = VERIFIED_STRING()
        } else if (device.trustLevel == .removed) {
            trustLevelLabel.text = Removed_By_Server()
        } else {
            trustLevelLabel.text = UNTRUSTED_DEVICE_STRING()
        }
    }
    
    fileprivate func switchValueWithDevice(_ device: OMEMODevice) {
        if (trustSwitch.isOn) {
            device.trustLevel = .trustedUser
            if (device.isExpired()){
                device.lastSeenDate = Date()
            }
        } else {
            device.trustLevel = .untrusted
        }
        rowDescriptor.value = device
        updateCellFromDevice(device)
    }
    
    fileprivate func updateCellFromFingerprint(_ fingerprint: OTRFingerprint) {
        fingerprintLabel.text = (fingerprint.fingerprint as NSData).humanReadableFingerprint()
        lastSeenLabel.text = "OTR"
        if (fingerprint.trustLevel == .trustedUser ||
            fingerprint.trustLevel == .trustedTofu) {
            trustSwitch.isOn = true
        } else {
            trustSwitch.isOn = false
        }
        if (fingerprint.trustLevel == .trustedTofu) {
            trustLevelLabel.text = "TOFU"
        } else if (fingerprint.trustLevel == .trustedUser) {
            trustLevelLabel.text = VERIFIED_STRING()
        } else {
            trustLevelLabel.text = UNTRUSTED_DEVICE_STRING()
        }
    }
    
    fileprivate func switchValueWithFingerprint(_ fingerprint: OTRFingerprint) {
        if (trustSwitch.isOn) {
            fingerprint.trustLevel = .trustedUser
        } else {
            fingerprint.trustLevel = .untrustedUser
        }
        rowDescriptor.value = fingerprint
        updateCellFromFingerprint(fingerprint)
    }

    
}
