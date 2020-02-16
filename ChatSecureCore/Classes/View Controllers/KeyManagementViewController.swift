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
import OTRKit

/** Crypto Chooser row tags */
private struct RowTags {
    static let DefaultRowTag = "DefaultRowTag"
    static let PlaintextRowTag = "PlaintextRowTag"
    static let OTRRowTag = "OTRRowTag"
    static let OMEMORowTag = "OMEMORowTag"
    static let ShowAdvancedCryptoSettingsTag = "ShowAdvancedCryptoSettingsTag"
}

open class KeyManagementViewController: XLFormViewController {
    
    @objc open var completionBlock: (()->Void)?

    private let accountKey:String?
    private let connections: DatabaseConnections
    
    private lazy var signalCoordinator:OTROMEMOSignalCoordinator? = {
        guard let accountKey = accountKey,
            let account = self.connections.ui.fetch({ (transaction) in
            OTRXMPPAccount.fetchObject(withUniqueID: accountKey, transaction: transaction)
        }),
            let xmpp = OTRProtocolManager.shared.xmppManager(for: account) else {
            return nil
        }
        return xmpp.omemoSignalCoordinator
    }()
    
    @objc public init(accountKey:String?,
                      connections: DatabaseConnections,
                      form: XLFormDescriptor) {
        self.accountKey = accountKey
        self.connections = connections
        super.init(nibName: nil, bundle: nil)
        
        self.form = form
    }
    
    required public init!(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        // gotta register cell before super
        OMEMODeviceFingerprintCell.registerCellClass(OMEMODeviceFingerprintCell.defaultRowDescriptorType())
        UserInfoProfileCell.registerCellClass(UserInfoProfileCell.defaultRowDescriptorType())

        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: SAVE_STRING(), style: .done, target: self, action: #selector(saveButtonPressed(_:)))
        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        // Overriding superclass behaviour. This prevents the red icon on left of cell for deletion. Just want swipe to delete on device/fingerprint.
        self.tableView.setEditing(false, animated: false)
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func removeDevice(_ device: OMEMODevice) {
        connections.write.asyncReadWrite {
            let parent = device.parent(with: $0)
            var _account: OTRXMPPAccount?
            if let buddy = parent as? OTRXMPPBuddy {
                _account = buddy.account(with: $0) as? OTRXMPPAccount
            } else if let account = parent as? OTRXMPPAccount {
                _account = account
            }
            guard let account = _account,
                let xmpp = OTRProtocolManager.shared.xmppManager(for: account),
                let signal = xmpp.omemoSignalCoordinator else {
                return
            }
            signal.removeDevice([device], completion: { (success) in
                if !success {
                    DDLogError("Error removing OMEMO device")
                }
            })
        }
    }
    
    @objc open func saveButtonPressed(_ sender: AnyObject?) {
        var devicesToSave: [OMEMODevice] = []
        var otrFingerprintsToSave: [OTRFingerprint] = []
        for (_, value) in form.formValues() {
            switch value {
            case let device as OMEMODevice:
                devicesToSave.append(device)
            case let fingerprint as OTRFingerprint:
                otrFingerprintsToSave.append(fingerprint)
            default:
                break
            }
        }
        OTRDatabaseManager.sharedInstance().writeConnection?.asyncReadWrite({ (t: YapDatabaseReadWriteTransaction) in
            for viewedDevice in devicesToSave {
                if var device = t.object(forKey: viewedDevice.uniqueId, inCollection: OMEMODevice.collection) as? OMEMODevice {
                    device = device.copy() as! OMEMODevice
                    device.trustLevel = viewedDevice.trustLevel
                    
                    if (device.trustLevel == .trustedUser && device.isExpired()) {
                        device.lastSeenDate = viewedDevice.lastSeenDate
                    }
                    
                    device.save(with: t)
                }
            }
        })
        
        otrFingerprintsToSave.forEach { (fingerprint) in
            OTRProtocolManager.encryptionManager.save(fingerprint)
        }
        if let completion = self.completionBlock {
            completion()
        }
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func isAbleToDeleteCellAtIndexPath(_ indexPath:IndexPath) -> Bool {
        if let rowDescriptor = self.form.formRow(atIndex: indexPath) {
            
            switch rowDescriptor.value {
            case let device as OMEMODevice:
                if let myBundle = self.signalCoordinator?.fetchMyBundle(),
                    let accountKey = self.accountKey {
                    // This is only used to compare so we don't allow delete UI on our device
                    let thisDeviceYapKey = OMEMODevice.yapKey(withDeviceId: NSNumber(value: myBundle.deviceId as UInt32), parentKey: accountKey, parentCollection: OTRAccount.collection)
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
    
    public static func cryptoChooserRows(_ buddy: OTRBuddy, connection: YapDatabaseConnection) -> [XLFormRowDescriptor] {
        
        let bestAvailableRow = XLFormRowDescriptor(tag: RowTags.DefaultRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: Best_Available())
        let plaintextOnlyRow = XLFormRowDescriptor(tag: RowTags.PlaintextRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: Plaintext_Only())
        let plaintextOtrRow = XLFormRowDescriptor(tag: RowTags.PlaintextRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: Plaintext_Opportunistic_OTR())
        let otrRow = XLFormRowDescriptor(tag: RowTags.OTRRowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: "OTR")
        let omemoRow = XLFormRowDescriptor(tag: RowTags.OMEMORowTag, rowType: XLFormRowDescriptorTypeBooleanCheck, title: "OMEMO")
        
        var hasDevices = false
        
        connection.read { (transaction: YapDatabaseReadTransaction) in
            if OMEMODevice.allDevices(forParentKey: buddy.uniqueId, collection: type(of: buddy).collection, transaction: transaction).count > 0 {
                hasDevices = true
            }
        }
        
        if (!hasDevices) {
            omemoRow.disabled = NSNumber(value: true as Bool)
        }
        
        let trueValue = NSNumber(value: true as Bool)
        switch buddy.preferredSecurity {
        case .plaintextOnly:
            plaintextOnlyRow.value = trueValue
            break
        case .bestAvailable:
            bestAvailableRow.value = trueValue
            break
        case .OTR:
            otrRow.value = trueValue
            break
        case .OMEMO:
            omemoRow.value = trueValue
            break
        case .omemOandOTR:
            omemoRow.value = trueValue
            break
        case .plaintextWithOTR:
            plaintextOtrRow.value = trueValue
        @unknown default:
            fatalError("Unrecognized value!")
        }
        
        let formRows = [bestAvailableRow, plaintextOnlyRow, plaintextOtrRow, otrRow, omemoRow]
        
        var currentRow: XLFormRowDescriptor? = nil
        var rowsToDeselect: NSMutableSet = NSMutableSet()
        let onChangeBlock = { (oldValue: Any?, newValue: Any?, rowDescriptor: XLFormRowDescriptor) in
            // Prevent infinite loops
            // Allow deselection
            if rowsToDeselect.count > 0 {
                rowsToDeselect.remove(rowDescriptor)
                return
            }
            if currentRow != nil {
                return
            }
            currentRow = rowDescriptor
            
            // Don't allow user to unselect a true value
            if (newValue as AnyObject?)?.boolValue == false {
                rowDescriptor.value = NSNumber(value: true as Bool)
                currentRow = nil
                return
            }
            
            // Deselect other rows
            rowsToDeselect = NSMutableSet(array: formRows.filter({ $0 != rowDescriptor }))
            for row in rowsToDeselect {
                guard let row = row as? XLFormRowDescriptor else {
                    continue
                }
                let newValue = NSNumber(value: false as Bool)
                row.value = newValue
                // Wow that's janky
                (row.sectionDescriptor.formDescriptor.delegate as! XLFormViewControllerDelegate).reloadFormRow!(row)
            }
            
            var preferredSecurity: OTRSessionSecurity = .bestAvailable
            if (plaintextOnlyRow.value as AnyObject?)?.boolValue == true {
                preferredSecurity = .plaintextOnly
            } else if (otrRow.value as AnyObject?)?.boolValue == true {
                preferredSecurity = .OTR
            } else if (omemoRow.value as AnyObject?)?.boolValue == true {
                preferredSecurity = .OMEMO
            } else if (bestAvailableRow.value as AnyObject?)?.boolValue == true {
                preferredSecurity = .bestAvailable
            } else if (plaintextOtrRow.value as AnyObject?)?.boolValue == true {
                preferredSecurity = .plaintextWithOTR
            }
            
            OTRDatabaseManager.sharedInstance().writeConnection?.readWrite({ (transaction: YapDatabaseReadWriteTransaction) in
                guard var buddy = transaction.object(forKey: buddy.uniqueId, inCollection: type(of: buddy).collection) as? OTRBuddy else {
                    return
                }
                guard let account = buddy.account(with: transaction) else {
                    return
                }
                buddy = buddy.copy() as! OTRBuddy
                buddy.preferredSecurity = preferredSecurity
                buddy.save(with: transaction)
                // Cancel OTR session if plaintext or omemo only
                if (preferredSecurity == .plaintextOnly || preferredSecurity == .OMEMO) {
                    OTRProtocolManager.encryptionManager.otrKit.disableEncryption(withUsername: buddy.username, accountName: account.username, protocol: account.protocolTypeString())
                }
            })
            currentRow = nil
        }
        
        for row in formRows {
            row.onChangeBlock = onChangeBlock
        }

        return formRows
    }
    
    // MARK:  UITableView Delegate overrides
    
    open override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if  self.isAbleToDeleteCellAtIndexPath(indexPath) {
            return true
        }
        return false
    }
    
    open override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if  self.isAbleToDeleteCellAtIndexPath(indexPath) {
            return .delete
        }
        return .none
    }
    
    open override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete,
           self.isAbleToDeleteCellAtIndexPath(indexPath)  {
            guard let rowDescriptor = self.form.formRow(atIndex: indexPath) else {
                return
            }
            rowDescriptor.sectionDescriptor.removeFormRow(rowDescriptor)
            switch rowDescriptor.value {
            case let device as OMEMODevice:
                self.removeDevice(device)
                break
            case let fingerprint as OTRFingerprint:
                do {
                    try OTRProtocolManager.encryptionManager.otrKit.delete(fingerprint)
                } catch {
                    DDLogError("Error deleting fingerprint: \(error)")
                }
                break
            default:
                break
            }
        }
    }

    /// MARK: Static Methods
    
    @objc public static func profileFormDescriptorForAccount(_ account: OTRXMPPAccount?, buddies: [OTRXMPPBuddy], connection: YapDatabaseConnection) -> XLFormDescriptor {
        let otrKit = OTRProtocolManager.encryptionManager.otrKit
        let form = XLFormDescriptor(title: Profile_String())
        
        var _yourProfileSection: XLFormSectionDescriptor?
        if let account = account,
            let xmpp = OTRProtocolManager.shared.xmppManager(for: account),
            let myBundle = xmpp.omemoSignalCoordinator?.fetchMyBundle() {
            
            let section = XLFormSectionDescriptor.formSection(withTitle: Me_String())
            let yourProfileRow = XLFormRowDescriptor(tag: account.uniqueId, rowType: UserInfoProfileCell.defaultRowDescriptorType())
            yourProfileRow.value = account
            section.addFormRow(yourProfileRow)
            
            let thisDevice = OMEMODevice(deviceId: NSNumber(value: myBundle.deviceId as UInt32), trustLevel: .trustedUser, parentKey: account.uniqueId, parentCollection: type(of: account).collection, publicIdentityKeyData: myBundle.identityKey, lastSeenDate: Date())
            let ourOtherDevices = connection.fetch {
                OMEMODevice.allDevices(forParentKey: account.uniqueId, collection: OTRXMPPAccount.collection, transaction: $0)
                }?.filter {
                    $0.uniqueId != thisDevice.uniqueId
            } ?? []
            
            let allMyDevices = [thisDevice] + ourOtherDevices
            allMyDevices.filter { $0.publicIdentityKeyData != nil }
                .forEach { device in
                let row = XLFormRowDescriptor(tag: device.uniqueId, rowType: OMEMODeviceFingerprintCell.defaultRowDescriptorType())
                row.value = device.copy()
                
                // Don't allow editing of your own device
                if device.uniqueId == thisDevice.uniqueId {
                    row.disabled = true
                }
                
                section.addFormRow(row)
            }
            
            if let myFingerprint = otrKit.fingerprint(forAccountName: account.username, protocol: account.protocolTypeString()) {
                let row = XLFormRowDescriptor(tag: (myFingerprint.fingerprint as NSData).otr_hexString(), rowType: OMEMODeviceFingerprintCell.defaultRowDescriptorType())
                row.value = myFingerprint
                row.disabled = true
                section.addFormRow(row)
            }

            _yourProfileSection = section
        }
        
        
        // TODO - Sort ourDevices and theirDevices by lastSeen
        
        let addDevicesToSection: ([OMEMODevice], XLFormSectionDescriptor) -> Void = { devices, section in
            for device in devices {
                guard let _ = device.publicIdentityKeyData else {
                    continue
                }
                let row = XLFormRowDescriptor(tag: device.uniqueId, rowType: OMEMODeviceFingerprintCell.defaultRowDescriptorType())
                row.value = device.copy()
                
                section.addFormRow(row)
            }
        }
        
        let allFingerprints = otrKit.allFingerprints()
        let addFingerprintsToSection: ([OTRFingerprint], XLFormSectionDescriptor) -> Void = { fingerprints, section in
            for fingerprint in fingerprints {
                let row = XLFormRowDescriptor(tag: (fingerprint.fingerprint as NSData).otr_hexString(), rowType: OMEMODeviceFingerprintCell.defaultRowDescriptorType())
                row.value = fingerprint
                section.addFormRow(row)
            }
        }
        
        var theirSections: [XLFormSectionDescriptor] = []
        
        // Add section for each buddy's device
        for buddy in buddies {
            let theirSection = XLFormSectionDescriptor.formSection(withTitle: buddy.username)

            let buddyRow = XLFormRowDescriptor(tag: buddy.uniqueId, rowType: UserInfoProfileCell.defaultRowDescriptorType())
            buddyRow.value = buddy
            theirSection.addFormRow(buddyRow)
            var theirDevices: [OMEMODevice] = []
            connection.read({ (transaction: YapDatabaseReadTransaction) in
                theirDevices = OMEMODevice.allDevices(forParentKey: buddy.uniqueId, collection: type(of: buddy).collection, transaction: transaction)
            })
            // Only show OTR keys for 1:1 chats with an account
            if let account = account {
                let theirFingerprints = allFingerprints.filter({ (fingerprint: OTRFingerprint) -> Bool in
                    return fingerprint.username == buddy.username &&
                        fingerprint.accountName == account.username
                })
                addFingerprintsToSection(theirFingerprints, theirSection)
            }
            
            addDevicesToSection(theirDevices, theirSection)
            theirSections.append(theirSection)
        }
 
        
        var sectionsToAdd: [XLFormSectionDescriptor] = []
        sectionsToAdd.append(contentsOf: theirSections)
        
        // cryptoChooserRows is only meaningful for 1:1 conversations at the moment
        if buddies.count == 1,
            account != nil {
            let buddy = buddies.first!
            let cryptoSection = XLFormSectionDescriptor.formSection(withTitle: Advanced_Encryption_Settings())
            cryptoSection.footerTitle = Advanced_Crypto_Warning()
            let showAdvancedSwitch = XLFormRowDescriptor.init(tag: RowTags.ShowAdvancedCryptoSettingsTag, rowType: XLFormRowDescriptorTypeBooleanSwitch, title: Show_Advanced_Encryption_Settings())
            showAdvancedSwitch.value = NSNumber(value: false as Bool)
            let cryptoChooser = cryptoChooserRows(buddy, connection: connection)
            for row in cryptoChooser {
                cryptoSection.addFormRow(row)
            }
            cryptoSection.hidden = "$\(RowTags.ShowAdvancedCryptoSettingsTag)==0"
            let buddySection = theirSections.first!
            buddySection.addFormRow(showAdvancedSwitch)
            sectionsToAdd.append(cryptoSection)
        }
        
        if let section = _yourProfileSection {
            sectionsToAdd.append(section)
        }
    
        for section in sectionsToAdd {
            if section.formRows.count > 0 {
                form.addFormSection(section)
            }
        }
        
        return form
    }
    
    // MARK: - UITableViewDelegate
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = self.tableView(tableView, cellForRowAt: indexPath) as? OMEMODeviceFingerprintCell else {
            return
        }
        var fingerprint = ""
        var username = ""
        var cryptoType = ""
        if let device = cell.rowDescriptor.value as? OMEMODevice {
            cryptoType = "OMEMO"
            fingerprint = device.humanReadableFingerprint
            self.connections.ui.read({ (transaction) in
                if let buddy = transaction.object(forKey: device.parentKey, inCollection: device.parentCollection) as? OTRBuddy {
                    username = buddy.username
                }
            })
        }
        if let otrFingerprint = cell.rowDescriptor.value as? OTRFingerprint {
            cryptoType = "OTR"
            fingerprint = (otrFingerprint.fingerprint as NSData).humanReadableFingerprint()
            username = otrFingerprint.username
        }
        if fingerprint.count == 0 || username.count == 0 || cryptoType.count == 0 {
            return
        }
        let stringToShare = "\(username): \(cryptoType) \(fingerprint)"
        let activityViewController = UIActivityViewController(activityItems: [stringToShare], applicationActivities: nil)
        if let ppc = activityViewController.popoverPresentationController {
            ppc.sourceView = cell
            ppc.sourceRect = cell.frame
        }
        present(activityViewController, animated: true, completion: nil)
    }

}

extension OMEMODevice: XLFormOptionObject {
    public func formDisplayText() -> String {
        return humanReadableFingerprint
    }
    
    public func formValue() -> Any {
        return self
    }
}

extension OTRFingerprint: XLFormOptionObject {
    public func formDisplayText() -> String {
        return (fingerprint as NSData).humanReadableFingerprint()
    }
    
    public func formValue() -> Any {
        return self
    }
}
