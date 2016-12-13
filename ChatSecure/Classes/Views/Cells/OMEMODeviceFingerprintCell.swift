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


public extension XLFormBaseCell {
    
    public class func defaultRowDescriptorType() -> String {
        let type = NSStringFromClass(self)
        return type
    }
    
    public class func registerCellClass(forType: String) {
        let bundle = OTRAssets.resourcesBundle()
        let path = bundle.bundlePath
        let bundleName = (path as NSString).lastPathComponent
        let className = bundleName + "/" + NSStringFromClass(self)
        XLFormViewController.cellClassesForRowDescriptorTypes().setObject(className, forKey: forType)
    }
}

@objc(OMEMODeviceFingerprintCell)
public class OMEMODeviceFingerprintCell: XLFormBaseCell {
    
    @IBOutlet weak var fingerprintLabel: UILabel!
    @IBOutlet weak var trustSwitch: UISwitch!
    @IBOutlet weak var lastSeenLabel: UILabel!
    @IBOutlet weak var trustLevelLabel: UILabel!
    
    private static let intervalFormatter = TTTTimeIntervalFormatter()
    
    public override class func formDescriptorCellHeightForRowDescriptor(rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 90
    }
    
    public override func update() {
        super.update()
        if let device = rowDescriptor.value as? OTROMEMODevice {
            updateCellFromDevice(device)
        }
        if let fingerprint = rowDescriptor.value as? OTRFingerprint {
            updateCellFromFingerprint(fingerprint)
        }
        let enabled = !rowDescriptor.isDisabled()
        trustSwitch.enabled = enabled
        fingerprintLabel.enabled = enabled
        lastSeenLabel.enabled = enabled
    }
    
    @IBAction func switchValueChanged(sender: UISwitch) {
        if let device = rowDescriptor.value as? OTROMEMODevice {
            switchValueWithDevice(device)
        }
        if let fingerprint = rowDescriptor.value as? OTRFingerprint {
            switchValueWithFingerprint(fingerprint)
        }
    }
    
    private func updateCellFromDevice(device: OTROMEMODevice) {
        let trusted = device.isTrusted()
        trustSwitch.on = trusted
        
        // we've already filtered out devices w/o public keys
        // so publicIdentityKeyData should never be nil
        let fingerprint = device.humanReadableFingerprint
        
        fingerprintLabel.text = fingerprint
        let interval = -NSDate().timeIntervalSinceDate(device.lastSeenDate)
        let since = self.dynamicType.intervalFormatter.stringForTimeInterval(interval)
        let lastSeen = "OMEMO: " + since
        lastSeenLabel.text = lastSeen
        if (device.trustLevel == .TrustedTofu) {
            trustLevelLabel.text = "TOFU"
        } else if (device.trustLevel == .TrustedUser) {
            trustLevelLabel.text = NSLocalizedString("Verified", comment: "")
        } else {
            trustLevelLabel.text = NSLocalizedString("Untrusted", comment: "")
        }
    }
    
    private func switchValueWithDevice(device: OTROMEMODevice) {
        if (trustSwitch.on) {
            device.trustLevel = .TrustedUser
            if (device.isExpired()){
                device.lastSeenDate = NSDate()
            }
        } else {
            device.trustLevel = .Untrusted
        }
        rowDescriptor.value = device
        updateCellFromDevice(device)
    }
    
    private func updateCellFromFingerprint(fingerprint: OTRFingerprint) {
        fingerprintLabel.text = fingerprint.fingerprint.humanReadableFingerprint()
        lastSeenLabel.text = "OTR"
        if (fingerprint.trustLevel == .TrustedUser ||
            fingerprint.trustLevel == .TrustedTofu) {
            trustSwitch.on = true
        } else {
            trustSwitch.on = false
        }
        if (fingerprint.trustLevel == .TrustedTofu) {
            trustLevelLabel.text = "TOFU"
        } else if (fingerprint.trustLevel == .TrustedUser) {
            trustLevelLabel.text = NSLocalizedString("Verified", comment: "")
        } else {
            trustLevelLabel.text = NSLocalizedString("Untrusted", comment: "")
        }
    }
    
    private func switchValueWithFingerprint(fingerprint: OTRFingerprint) {
        if (trustSwitch.on) {
            fingerprint.trustLevel = .TrustedUser
        } else {
            fingerprint.trustLevel = .UntrustedUser
        }
        rowDescriptor.value = fingerprint
        updateCellFromFingerprint(fingerprint)
    }

    
}
