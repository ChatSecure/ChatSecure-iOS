//
//  OTRUsernameCell.swift
//  ChatSecure
//
//  Created by Christopher Ballinger on 8/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

import UIKit
import XLForm
import ParkedTextField

public class OTRUsernameCell: XLFormBaseCell, UITextFieldDelegate {

    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var usernameField: ParkedTextField!
    
    static let kOTRFormRowDescriptorTypeUsername = "kOTRFormRowDescriptorTypeUsername"
    static let UsernameKey = "username"
    static let DomainKey = "domain"
    
    deinit {
        self.usernameField.delegate = nil
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.usernameField.delegate = self
    }
    
    override public class func initialize() {
        // Register xib
        XLFormViewController.cellClassesForRowDescriptorTypes()
            .setObject("OTRUsernameCell",
                forKey: OTRUsernameCell.kOTRFormRowDescriptorTypeUsername)
    }
    
    // MARK: XLFormBaseCell overrides
    
    override public func configure() {
        super.configure()
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }
    
    /*
    override public func highlight() {
        super.highlight()
        self.usernameLabel.textColor = self.tintColor
    }
    
    override public func unhighlight() {
        super.unhighlight()
        self.formViewController().updateFormRow(self.rowDescriptor)
    }
    */
   
    override public func update() {
        super.update()
        if let value: Dictionary<String, String> = self.rowDescriptor!.value as? Dictionary<String, String> {
            if let username = value[OTRUsernameCell.UsernameKey] {
                if username.characters.count > 0 {
                    self.usernameField.typedText = username
                }
            }
            if let domain = value[OTRUsernameCell.DomainKey] {
                if domain.characters.count > 0 {
                    self.usernameField.parkedText = "@" + domain
                }
            }
        } else {
            assert(false, "Value must be a Dictionary<String, String>")
        }
    }
    
    // MARK: XLFormDescriptorCell
    
    func formDescriptorCellHeightForRowDescriptor(rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 45
    }
    
    override public func formDescriptorCellCanBecomeFirstResponder() -> Bool {
        return true
    }
    
    override public func formDescriptorCellBecomeFirstResponder() -> Bool {
        self.highlight()
        return self.usernameField.becomeFirstResponder()
    }
    
    // MARK: UITextField value changes
    
    @IBAction func textFieldValueChanged(sender: ParkedTextField) {
        let value = OTRUsernameCell.createRowDictionaryValueForUsername(sender.typedText, domain: sender.parkedText)
        if let row = rowDescriptor {
            row.value = value
        }
    }
    
    // MARK: Private methods
    
    public static func createRowDictionaryValueForUsername(username: String?, domain: String?) -> Dictionary<String, String> {
        let unwrappedUsername = username ?? ""
        let unwrappedDomain = domain ?? ""
        let value: Dictionary<String, String> = [OTRUsernameCell.UsernameKey: unwrappedUsername, OTRUsernameCell.DomainKey: unwrappedDomain]
        return value
    }
    
}
