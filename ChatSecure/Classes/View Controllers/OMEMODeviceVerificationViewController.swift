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

public class UserProfileViewController: XLFormViewController {
    
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
        UserInfoProfileCell.registerCellClass(UserInfoProfileCell.defaultRowDescriptorType())

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

    
    public static func profileFormDescriptorForAccount(account: OTRAccount, buddies: [OTRBuddy], connection: YapDatabaseConnection) -> XLFormDescriptor {
        let form = XLFormDescriptor(title: NSLocalizedString("Profile", comment: ""))
        
        
        let yourProfileSection = XLFormSectionDescriptor.formSectionWithTitle(NSLocalizedString("Me", comment: ""))
        let yourProfileRow = XLFormRowDescriptor(tag: account.uniqueId, rowType: UserInfoProfileCell.defaultRowDescriptorType())
        yourProfileRow.value = account
        yourProfileSection.addFormRow(yourProfileRow)
        
        guard let xmpp = OTRProtocolManager.sharedInstance().protocolForAccount(account) as? OTRXMPPManager else {
            return form
        }
        guard let myBundle = xmpp.omemoSignalCoordinator.fetchMyBundle() else {
            return form
        }
        let thisDevice = OTROMEMODevice(deviceId: NSNumber(unsignedInt: myBundle.deviceId), trustLevel: .TrustedUser, parentKey: account.uniqueId, parentCollection: account.dynamicType.collection(), publicIdentityKeyData: myBundle.identityKey, lastSeenDate: NSDate())
        var ourDevices: [OTROMEMODevice] = []
        connection.readWithBlock { (transaction: YapDatabaseReadTransaction) in
            ourDevices = OTROMEMODevice.allDevicesForParentKey(account.uniqueId, collection: account.dynamicType.collection(), transaction: transaction)
        }

        
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
                
                // Don't allow editing of your own device
                if device.uniqueId == thisDevice.uniqueId {
                    row.disabled = true
                }
                
                section.addFormRow(row)
            }
        }
        
        
        form.addFormSection(yourProfileSection)
        
        var allMyDevices: [OTROMEMODevice] = []
        allMyDevices.append(thisDevice)
        allMyDevices.appendContentsOf(ourFilteredDevices)
        addDevicesToSection(allMyDevices, yourProfileSection)
        
        var theirSections: [XLFormSectionDescriptor] = []
        
        // Add section for each buddy's device
        for buddy in buddies {
            let theirSection = XLFormSectionDescriptor.formSectionWithTitle(buddy.username)
            let buddyRow = XLFormRowDescriptor(tag: buddy.uniqueId, rowType: UserInfoProfileCell.defaultRowDescriptorType())
            buddyRow.value = buddy
            theirSection.addFormRow(buddyRow)
            var theirDevices: [OTROMEMODevice] = []
            connection.readWithBlock({ (transaction: YapDatabaseReadTransaction) in
                theirDevices = OTROMEMODevice.allDevicesForParentKey(buddy.uniqueId, collection: buddy.dynamicType.collection(), transaction: transaction)
            })
            addDevicesToSection(theirDevices, theirSection)
            theirSections.append(theirSection)
        }
 
        
        var sectionsToAdd: [XLFormSectionDescriptor] = []
        sectionsToAdd.append(yourProfileSection)
        sectionsToAdd.appendContentsOf(theirSections)
    
        for section in sectionsToAdd {
            if section.formRows.count > 0 {
                form.addFormSection(section)
            }
        }
        
        return form
    }
    
    // MARK: - UITableViewDelegate
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let cell = self.tableView(tableView, cellForRowAtIndexPath: indexPath) as? OMEMODeviceFingerprintCell else {
            return
        }
        guard let device = cell.rowDescriptor.value as? OTROMEMODevice else {
            return
        }
        let fingerprint = device.humanReadableFingerprint
        
        let activityViewController = UIActivityViewController(activityItems: [fingerprint], applicationActivities: nil)
        if let ppc = activityViewController.popoverPresentationController {
            ppc.sourceView = cell
            ppc.sourceRect = cell.frame
        }
        presentViewController(activityViewController, animated: true, completion: nil)
    }

}
