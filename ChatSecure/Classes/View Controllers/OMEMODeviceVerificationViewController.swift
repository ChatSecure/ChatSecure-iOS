//
//  OMEMODeviceVerificationViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 10/13/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import XLForm
import XMPPFramework
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
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(doneButtonPressed(_:)))
        // Do any additional setup after loading the view.
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func doneButtonPressed(sender: AnyObject?) {
        for (key, value) in form.formValues() {
            connection?.asyncReadWriteWithBlock({ (t: YapDatabaseReadWriteTransaction) in
                if var device = t.objectForKey(key as! String, inCollection: OTROMEMODevice.collection()) as? OTROMEMODevice {
                    device = device.copy() as! OTROMEMODevice
                    let trust = value.boolValue!.boolValue
                    if (trust) {
                        device.trustLevel = .TrustLevelTrustedUser
                    } else {
                        device.trustLevel = .TrustLevelUntrusted
                    }
                    device.saveWithTransaction(t)
                }
            })
        }
        dismissViewControllerAnimated(true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    public static func formDescriptorForThisDevice(thisDevice: OTROMEMODevice, ourDevices: [OTROMEMODevice], theirDevices: [OTROMEMODevice]) -> XLFormDescriptor {
        let form = XLFormDescriptor(title: NSLocalizedString("Verify Devices", comment: ""))
        let thisSection = XLFormSectionDescriptor.formSectionWithTitle(NSLocalizedString("This Device", comment: ""))
        let ourSection = XLFormSectionDescriptor.formSectionWithTitle(NSLocalizedString("Our Other Devices", comment: ""))
        let theirSection = XLFormSectionDescriptor.formSectionWithTitle(NSLocalizedString("Their Devices", comment: ""))
        
        let ourFilteredDevices = ourDevices.filter({ (device: OTROMEMODevice) -> Bool in
            return device.uniqueId != thisDevice.uniqueId
        })
        
        let addDevicesToSection: ([OTROMEMODevice], XLFormSectionDescriptor) -> Void = { devices, section in
            for device in devices {
                guard let key = device.publicIdentityKeyData else {
                    continue
                }
                //let key = device.publicIdentityKeyData
                let hex = key.xmpp_hexStringValue()
                let row = XLFormRowDescriptor(tag: device.uniqueId, rowType: XLFormRowDescriptorTypeBooleanSwitch, title: hex)
                row.value = device.isTrusted()
                let action = XLFormAction()
                action.formBlock = { _ in
                    print("changed device: \(device)")
                }
                row.action = action
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
