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
import OTRAssets

public class UserProfileViewController: XLFormViewController {
    
    public var completionBlock: dispatch_block_t?
    
    // Crypto Chooser row tags
    public static let DefaultRowTag = "DefaultRowTag"
    public static let PlaintextRowTag = "PlaintextRowTag"
    public static let OTRRowTag = "OTRRowTag"
    public static let OMEMORowTag = "OMEMORowTag"
    public static let ShowAdvancedCryptoSettingsTag = "ShowAdvancedCryptoSettingsTag"
    
    public let accountKey:String
    public var connection: YapDatabaseConnection
    
    lazy var signalCoordinator:OTROMEMOSignalCoordinator? = {
        var account:OTRAccount? = nil
        self.connection.readWithBlock { (transaction) in
            account = OTRAccount.fetchObjectWithUniqueID(self.accountKey, transaction: transaction)
        }
        
        guard let acct = account else {
            return nil
        }
        
        guard let xmpp = OTRProtocolManager.sharedInstance().protocolForAccount(acct) as? OTRXMPPManager else {
            return nil
        }
        return xmpp.omemoSignalCoordinator
    }()
    
    public init(accountKey:String, connection: YapDatabaseConnection, form: XLFormDescriptor) {
        self.accountKey = accountKey
        self.connection = connection
        super.init(nibName: nil, bundle: nil)
        
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
        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        // Overriding superclass behaviour. This prevents the red icon on left of cell for deletion. Just want swipe to delete on device/fingerprint.
        self.tableView.setEditing(false, animated: false)
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
        OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.asyncReadWriteWithBlock({ (t: YapDatabaseReadWriteTransaction) in
            for viewedDevice in devicesToSave {
                if var device = t.objectForKey(viewedDevice.uniqueId, inCollection: OTROMEMODevice.collection()) as? OTROMEMODevice {
                    device = device.copy() as! OTROMEMODevice
                    device.trustLevel = viewedDevice.trustLevel
                    
                    if (device.trustLevel == .TrustedUser && device.isExpired()) {
                        device.lastSeenDate = viewedDevice.lastSeenDate
                    }
                    
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
    
    private func isAbleToDeleteCellAtIndexPath(indexPath:NSIndexPath) -> Bool {
        if let rowDescriptor = self.form.formRowAtIndex(indexPath) {
            
            switch rowDescriptor.value {
            case let device as OTROMEMODevice:
                if let myBundle = self.signalCoordinator?.fetchMyBundle() {
                    // This is only used to compare so we don't allow delete UI on our device
                    let thisDeviceYapKey = OTROMEMODevice.yapKeyWithDeviceId(NSNumber(unsignedInt: myBundle.deviceId), parentKey: self.accountKey, parentCollection: OTRAccount.collection())
                    if device.uniqueId != thisDeviceYapKey {
                        return true
                    }
                }
            case let fingerprint as OTRFingerprint:
                if (fingerprint.accountName != fingerprint.username) {
                    return true
                }
            default:
                break
            }
        }
        return false
    }
    
    private func performEdit(action:UITableViewCellEditingStyle, indexPath:NSIndexPath) {
        if ( action == .Delete ) {
            if let rowDescriptor = self.form.formRowAtIndex(indexPath) {
                rowDescriptor.sectionDescriptor.removeFormRow(rowDescriptor)
                switch rowDescriptor.value {
                case let device as OTROMEMODevice:
                    
                    self.signalCoordinator?.removeDevice([device], completion: { (success) in
                        
                    })
                    break
                case let fingerprint as OTRFingerprint:
                    do {
                        try OTRProtocolManager.sharedInstance().encryptionManager.otrKit.deleteFingerprint(fingerprint)
                    } catch {
                        
                    }
                    break
                default:
                    break
                }
            }
        }
    }
    
    public static func cryptoChooserRows(buddy: OTRBuddy, connection: YapDatabaseConnection) -> [XLFormRowDescriptor] {
        
        let bestAvailableRow = XLFormRowDescriptor(tag: DefaultRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: Best_Available())
        let plaintextOnlyRow = XLFormRowDescriptor(tag: PlaintextRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: Plaintext_Only())
        let plaintextOtrRow = XLFormRowDescriptor(tag: PlaintextRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: Plaintext_Opportunistic_OTR())
        let otrRow = XLFormRowDescriptor(tag: OTRRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: "OTR")
        let omemoRow = XLFormRowDescriptor(tag: OMEMORowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: "OMEMO")
        let omemoOtrRow = XLFormRowDescriptor(tag: OMEMORowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: "OMEMO & OTR")

        
        var hasDevices = false
        
        connection.readWithBlock { (transaction: YapDatabaseReadTransaction) in
            if OTROMEMODevice.allDevicesForParentKey(buddy.uniqueId, collection: buddy.dynamicType.collection(), transaction: transaction).count > 0 {
                hasDevices = true
            }
        }
        
        if (!hasDevices) {
            omemoRow.disabled = NSNumber(bool: true)
            omemoOtrRow.disabled = NSNumber(bool: true)
        }
        
        let trueValue = NSNumber(bool: true)
        switch buddy.preferredSecurity {
        case .PlaintextOnly:
            plaintextOnlyRow.value = trueValue
            break
        case .BestAvailable:
            bestAvailableRow.value = trueValue
            break
        case .OTR:
            otrRow.value = trueValue
            break
        case .OMEMO:
            omemoRow.value = trueValue
            break
        case .OMEMOandOTR:
            omemoOtrRow.value = trueValue
            break
        case .PlaintextWithOTR:
            plaintextOtrRow.value = trueValue
        }
        
        let formRows = [bestAvailableRow, plaintextOnlyRow, plaintextOtrRow, otrRow, omemoRow, omemoOtrRow]
        
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
            
            var preferredSecurity: OTRSessionSecurity = .BestAvailable
            if plaintextOnlyRow.value?.boolValue == true {
                preferredSecurity = .PlaintextOnly
            } else if otrRow.value?.boolValue == true {
                preferredSecurity = .OTR
            } else if omemoRow.value?.boolValue == true {
                preferredSecurity = .OMEMO
            } else if bestAvailableRow.value?.boolValue == true {
                preferredSecurity = .BestAvailable
            } else if plaintextOtrRow.value?.boolValue == true {
                preferredSecurity = .PlaintextWithOTR
            } else if omemoOtrRow.value?.boolValue == true {
                preferredSecurity = .OMEMOandOTR
            }
            
            OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.readWriteWithBlock({ (transaction: YapDatabaseReadWriteTransaction) in
                guard var buddy = transaction.objectForKey(buddy.uniqueId, inCollection: buddy.dynamicType.collection()) as? OTRBuddy else {
                    return
                }
                guard let account = buddy.accountWithTransaction(transaction) else {
                    return
                }
                buddy = buddy.copy() as! OTRBuddy
                buddy.preferredSecurity = preferredSecurity
                buddy.saveWithTransaction(transaction)
                // Cancel OTR session if plaintext or omemo only
                if (preferredSecurity == .PlaintextOnly || preferredSecurity == .OMEMO) {
                    OTRProtocolManager.sharedInstance().encryptionManager.otrKit.disableEncryptionWithUsername(buddy.username, accountName: account.username, protocol: account.protocolTypeString())
                }
            })
            currentRow = nil
        }
        
        for row in formRows {
            row.onChangeBlock = onChangeBlock
        }

        return formRows
    }
    
//MARK UITableView Delegate overrides
    
    public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if  self.isAbleToDeleteCellAtIndexPath(indexPath) {
            return true
        }
        return false
    }
    
    public override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if  self.isAbleToDeleteCellAtIndexPath(indexPath) {
            return .Delete
        }
        return .None
    }
    
    public override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        self.performEdit(editingStyle, indexPath: indexPath)
    }
    
    
    public static func profileFormDescriptorForAccount(account: OTRAccount, buddies: [OTRBuddy], connection: YapDatabaseConnection) -> XLFormDescriptor {
        let form = XLFormDescriptor(title: Profile_String())
        
        let yourProfileSection = XLFormSectionDescriptor.formSectionWithTitle(Me_String())
        let yourProfileRow = XLFormRowDescriptor(tag: account.uniqueId, rowType: UserInfoProfileCell.defaultRowDescriptorType())
        yourProfileRow.value = account
        yourProfileSection.addFormRow(yourProfileRow)
        
        guard let xmpp = OTRProtocolManager.sharedInstance().protocolForAccount(account) as? OTRXMPPManager else {
            return form
        }
        guard let myBundle = xmpp.omemoSignalCoordinator?.fetchMyBundle() else {
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
            let cryptoSection = XLFormSectionDescriptor.formSectionWithTitle(Advanced_Encryption_Settings())
            cryptoSection.footerTitle = Advanced_Crypto_Warning()
            let showAdvancedSwitch = XLFormRowDescriptor.init(tag: self.ShowAdvancedCryptoSettingsTag, rowType: XLFormRowDescriptorTypeBooleanSwitch, title: Show_Advanced_Encryption_Settings())
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
            self.connection.readWithBlock({ (transaction) in
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
