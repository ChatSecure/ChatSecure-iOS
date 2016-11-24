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
    public var completionBlock: dispatch_block_t?
    
    // Crypto Chooser row tags
    public static let DefaultRowTag = "DefaultRowTag"
    public static let PlaintextRowTag = "PlaintextRowTag"
    public static let OTRRowTag = "OTRRowTag"
    public static let OMEMORowTag = "OMEMORowTag"
    public static let ShowAdvancedCryptoSettingsTag = "ShowAdvancedCryptoSettingsTag"
    
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
        var devicesToSave: [OTROMEMODevice] = []
        var otrFingerprintsToSave: [OTRFingerprint] = []
        for (_, value) in form.formValues() {
            switch value {
            case let device as OTROMEMODevice:
                devicesToSave.append(device)
            case let fingerprint as OTRFingerprint:
                otrFingerprintsToSave.append(fingerprint)
            default:
                break
            }
        }
        connection?.asyncReadWriteWithBlock({ (t: YapDatabaseReadWriteTransaction) in
            for viewedDevice in devicesToSave {
                if var device = t.objectForKey(viewedDevice.uniqueId, inCollection: OTROMEMODevice.collection()) as? OTROMEMODevice {
                    device = device.copy() as! OTROMEMODevice
                    device.trustLevel = viewedDevice.trustLevel
                    device.saveWithTransaction(t)
                }
            }
        })
        
        otrFingerprintsToSave.forEach { (fingerprint) in
            OTRProtocolManager.sharedInstance().encryptionManager.saveFingerprint(fingerprint)
        }
        if let completionBlock = completionBlock {
            completionBlock()
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    public static func cryptoChooserRows(buddy: OTRBuddy, connection: YapDatabaseConnection) -> [XLFormRowDescriptor] {
        
        let defaultRow = XLFormRowDescriptor(tag: DefaultRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: NSLocalizedString("Best Available", comment: ""))
        let plaintextRow = XLFormRowDescriptor(tag: PlaintextRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: NSLocalizedString("Plaintext (Opportunistic OTR)", comment: ""))
        let otrRow = XLFormRowDescriptor(tag: OTRRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: "OTR")
        let omemoRow = XLFormRowDescriptor(tag: OMEMORowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: "OMEMO")
        
        var hasDevices = false
        
        connection.readWithBlock { (transaction: YapDatabaseReadTransaction) in
            if OTROMEMODevice.allDevicesForParentKey(buddy.uniqueId, collection: buddy.dynamicType.collection(), transaction: transaction).count > 0 {
                hasDevices = true
            }
        }
        
        if (!hasDevices) {
            omemoRow.disabled = NSNumber(bool: true)
        }
        
        let trueValue = NSNumber(bool: true)
        switch buddy.preferredSecurity {
        case .Plaintext:
            plaintextRow.value = trueValue
            break
        case .Default:
            defaultRow.value = trueValue
            break
        case .OTR:
            otrRow.value = trueValue
            break
        case .OMEMO:
            omemoRow.value = trueValue
            break
        }
        
        let formRows = [defaultRow, plaintextRow, otrRow, omemoRow]
        
        var currentRow: XLFormRowDescriptor? = nil
        var rowsToDeselect: NSMutableSet = NSMutableSet()
        let onChangeBlock = { (oldValue: AnyObject?, newValue: AnyObject?, rowDescriptor: XLFormRowDescriptor) in
            // Prevent infinite loops
            // Allow deselection
            if rowsToDeselect.count > 0 {
                rowsToDeselect.removeObject(rowDescriptor)
                return
            }
            if currentRow != nil {
                return
            }
            currentRow = rowDescriptor
            
            // Don't allow user to unselect a true value
            if newValue?.boolValue == false {
                rowDescriptor.value = NSNumber(bool: true)
                currentRow = nil
                return
            }
            
            // Deselect other rows
            rowsToDeselect = NSMutableSet(array: formRows.filter({ $0 != rowDescriptor }))
            for row in rowsToDeselect {
                guard let row = row as? XLFormRowDescriptor else {
                    continue
                }
                let newValue = NSNumber(bool: false)
                row.value = newValue
                // Wow that's janky
                (row.sectionDescriptor.formDescriptor.delegate as! XLFormViewControllerDelegate).reloadFormRow!(row)
            }
            
            var preferredSecurity: OTRSessionSecurity = .Default
            if plaintextRow.value?.boolValue == true {
                preferredSecurity = .Plaintext
            } else if otrRow.value?.boolValue == true {
                preferredSecurity = .OTR
            } else if omemoRow.value?.boolValue == true {
                preferredSecurity = .OMEMO
            } else if defaultRow.value?.boolValue == true {
                preferredSecurity = .Default
            }
            connection.readWriteWithBlock({ (transaction: YapDatabaseReadWriteTransaction) in
                if var buddy = transaction.objectForKey(buddy.uniqueId, inCollection: buddy.dynamicType.collection()) as? OTRBuddy {
                    buddy = buddy.copy() as! OTRBuddy
                    buddy.preferredSecurity = preferredSecurity
                    buddy.saveWithTransaction(transaction)
                }
            })
            currentRow = nil
        }
        
        defaultRow.onChangeBlock = onChangeBlock
        plaintextRow.onChangeBlock = onChangeBlock
        otrRow.onChangeBlock = onChangeBlock
        omemoRow.onChangeBlock = onChangeBlock
        
        return formRows
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
        
        let otrKit = OTRProtocolManager.sharedInstance().encryptionManager.otrKit
        let allFingerprints = otrKit.allFingerprints()
        let myFingerprint = otrKit.fingerprintForAccountName(account.username, protocol: account.protocolTypeString())
        let addFingerprintsToSection: ([OTRFingerprint], XLFormSectionDescriptor) -> Void = { fingerprints, section in
            for fingerprint in fingerprints {
                let row = XLFormRowDescriptor(tag: fingerprint.fingerprint.otr_hexString(), rowType: OMEMODeviceFingerprintCell.defaultRowDescriptorType())
                if let myFingerprint = myFingerprint {
                    if (fingerprint === myFingerprint) {
                        // We implicitly trust ourselves with OTR
                        row.disabled = true
                    } else {
                        row.disabled = false
                    }
                }
                
                row.value = fingerprint
                
                section.addFormRow(row)
            }
        }
        
        var allMyDevices: [OTROMEMODevice] = []
        allMyDevices.append(thisDevice)
        allMyDevices.appendContentsOf(ourFilteredDevices)
        addDevicesToSection(allMyDevices, yourProfileSection)
        
        var theirSections: [XLFormSectionDescriptor] = []

        if let myFingerprint = myFingerprint {
            addFingerprintsToSection([myFingerprint], yourProfileSection)
        }
        
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
            let theirFingerprints = allFingerprints.filter({ (fingerprint: OTRFingerprint) -> Bool in
                return fingerprint.username == buddy.username &&
                fingerprint.accountName == account.username
            })

            addDevicesToSection(theirDevices, theirSection)
            addFingerprintsToSection(theirFingerprints, theirSection)
            theirSections.append(theirSection)
        }
 
        
        var sectionsToAdd: [XLFormSectionDescriptor] = []
        sectionsToAdd.appendContentsOf(theirSections)
        
        // cryptoChooserRows is only meaningful for 1:1 conversations at the moment
        if buddies.count == 1 {
            let buddy = buddies.first!
            let cryptoSection = XLFormSectionDescriptor.formSectionWithTitle(NSLocalizedString("Advanced Encryption Settings", comment: ""))
            cryptoSection.footerTitle = NSLocalizedString("Don't change these unless you really know what you're doing. By default we will always select the best available encryption method.", comment: "")
            let showAdvancedSwitch = XLFormRowDescriptor.init(tag: self.ShowAdvancedCryptoSettingsTag, rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("Show Advanced Encryption Settings", comment: ""))
            showAdvancedSwitch.value = NSNumber(bool: false)
            let cryptoChooser = cryptoChooserRows(buddy, connection: connection)
            for row in cryptoChooser {
                cryptoSection.addFormRow(row)
            }
            cryptoSection.hidden = "$\(ShowAdvancedCryptoSettingsTag)==0"
            let buddySection = theirSections.first!
            buddySection.addFormRow(showAdvancedSwitch)
            sectionsToAdd.append(cryptoSection)
        }
        
        sectionsToAdd.append(yourProfileSection)
    
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
        var fingerprint = ""
        var username = ""
        var cryptoType = ""
        if let device = cell.rowDescriptor.value as? OTROMEMODevice {
            cryptoType = "OMEMO"
            fingerprint = device.humanReadableFingerprint
            connection?.readWithBlock({ (transaction) in
                if let buddy = transaction.objectForKey(device.parentKey, inCollection: device.parentCollection) as? OTRBuddy {
                    username = buddy.username
                }
            })
        }
        if let otrFingerprint = cell.rowDescriptor.value as? OTRFingerprint {
            cryptoType = "OTR"
            fingerprint = otrFingerprint.fingerprint.humanReadableFingerprint()
            username = otrFingerprint.username
        }
        if fingerprint.characters.count == 0 || username.characters.count == 0 || cryptoType.characters.count == 0 {
            return
        }
        let stringToShare = "\(username): \(cryptoType) \(fingerprint)"
        let activityViewController = UIActivityViewController(activityItems: [stringToShare], applicationActivities: nil)
        if let ppc = activityViewController.popoverPresentationController {
            ppc.sourceView = cell
            ppc.sourceRect = cell.frame
        }
        presentViewController(activityViewController, animated: true, completion: nil)
    }

}
