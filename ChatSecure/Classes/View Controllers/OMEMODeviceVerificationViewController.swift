//
//  OMEMODeviceVerificationViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 10/13/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import XLForm
import YapDatabase

public class OMEMODeviceVerificationViewController: XLFormViewController {
    
    public var connection: YapDatabaseConnection?
    
    public init(connection: YapDatabaseConnection, form: XLFormDescriptor) {
        super.init(nibName: nil, bundle: nil)
        self.connection = connection
        self.form = form
    }
    
    required public init!(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        // gotta register cell before super
        OMEMODeviceFingerprintCell.registerCellClass(OMEMODeviceFingerprintCell.defaultRowDescriptorType())

        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(doneButtonPressed(_:)))
        // Do any additional setup after loading the view.
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func doneButtonPressed(sender: AnyObject?) {
        for (_, value) in form.formValues() {
            guard let viewedDevice = value as? OTROMEMODevice else {
                continue
            }
            connection?.asyncReadWriteWithBlock({ (t: YapDatabaseReadWriteTransaction) in
                if var device = t.objectForKey(viewedDevice.uniqueId, inCollection: OTROMEMODevice.collection()) as? OTROMEMODevice {
                    device = device.copy() as! OTROMEMODevice
                    device.trustLevel = viewedDevice.trustLevel
                    device.saveWithTransaction(t)
                }
            })
        }
        dismissViewControllerAnimated(true, completion: nil)
    }

    
    public static func formDescriptorForThisDevice(thisDevice: OTROMEMODevice, ourDevices: [OTROMEMODevice], theirDevices: [OTROMEMODevice]) -> XLFormDescriptor {
        let form = XLFormDescriptor(title: NSLocalizedString("Verify Devices", comment: ""))
        let thisSection = XLFormSectionDescriptor.formSectionWithTitle(NSLocalizedString("This Device", comment: ""))
        let ourSection = XLFormSectionDescriptor.formSectionWithTitle(NSLocalizedString("Our Other Devices", comment: ""))
        let theirSection = XLFormSectionDescriptor.formSectionWithTitle(NSLocalizedString("Their Devices", comment: ""))
        
        let ourFilteredDevices = ourDevices.filter({ (device: OTROMEMODevice) -> Bool in
            return device.uniqueId != thisDevice.uniqueId
        })
        
        // TODO - Sort ourDevices and theirDevices by lastSeen
        
        let addDevicesToSection: ([OTROMEMODevice], XLFormSectionDescriptor) -> Void = { devices, section in
            for device in devices {
                guard let _ = device.publicIdentityKeyData else {
                    continue
                }
                let row = XLFormRowDescriptor(tag: device.uniqueId, rowType: OMEMODeviceFingerprintCell.defaultRowDescriptorType()) 
                row.value = device.copy()
                
                // Removed devices cannot be re-trusted but are stored
                // for historical purposes
                if device.trustLevel == .Removed {
                    row.disabled = true
                }
                
                section.addFormRow(row)
            }
        }
        
        addDevicesToSection([thisDevice], thisSection)
        addDevicesToSection(ourFilteredDevices, ourSection)
        addDevicesToSection(theirDevices, theirSection)
        
        for row in thisSection.formRows {
            if let row = row as? XLFormRowDescriptor {
                row.disabled = true
            }
        }
        
        for section in [thisSection, ourSection, theirSection] {
            if section.formRows.count > 0 {
                form.addFormSection(section)
            }
        }
        
        return form
    }

}
