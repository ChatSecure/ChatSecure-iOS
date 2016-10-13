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

public class OMEMODeviceVerificationViewController: XLFormViewController {

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
    
    public static func formDescriptorForOurDevices(ourDevices: [OTROMEMODevice], theirDevices: [OTROMEMODevice]) -> XLFormDescriptor {
        let form = XLFormDescriptor(title: NSLocalizedString("Verify Devices", comment: ""))
        let ourSection = XLFormSectionDescriptor.formSectionWithTitle(NSLocalizedString("Our Devices", comment: ""))
        let theirSection = XLFormSectionDescriptor.formSectionWithTitle(NSLocalizedString("Their Devices", comment: ""))
        
        let addDevicesToSection: ([OTROMEMODevice], XLFormSectionDescriptor) -> Void = { devices, section in
            for device in devices {
                //guard let key = device.publicIdentityKeyData else {
                //    continue
                //}
                let key = device.publicIdentityKeyData
                let hex = key?.xmpp_hexStringValue()
                let row = XLFormRowDescriptor(tag: device.uniqueId, rowType: XLFormRowDescriptorTypeBooleanSwitch, title: hex)
                row.value = device.isTrusted()
                let action = XLFormAction()
                action.formBlock = { _ in
                    print("changed device: \(device)")
                }
                section.addFormRow(row)
            }
        }
        
        addDevicesToSection(ourDevices, ourSection)
        addDevicesToSection(theirDevices, theirSection)
        
        form.addFormSection(ourSection)
        form.addFormSection(theirSection)
        
        return form
    }

}
