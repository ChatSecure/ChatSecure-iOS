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

public class OTRUsernameValidator: NSObject, XLFormValidatorProtocol {
    public func isValid(row: XLFormRowDescriptor!) -> XLFormValidationStatus! {
        var isValid = false
        if let value: Dictionary<String, String> = row.value as? Dictionary<String, String> {
            var hasUsername = false
            if let username = value[OTRUsernameCell.UsernameKey] {
                if count(username) > 0 {
                    hasUsername = true
                }
            }
            var hasDomain = false
            if let domain = value[OTRUsernameCell.DomainKey] {
                if count(domain) > 0 {
                    hasDomain = true
                }
            }
            isValid = hasUsername && hasDomain
        } else {
            assert(false, "Value must be a Dictionary<String, String>")
        }
        let status: XLFormValidationStatus = XLFormValidationStatus(msg: "", status: isValid, rowDescriptor: row)
        return status
    }
}

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
    
    
    override public func highlight() {
        super.highlight()
        self.usernameLabel.textColor = self.tintColor
    }
    
    override public func unhighlight() {
        super.unhighlight()
        self.formViewController().updateFormRow(self.rowDescriptor)
    }
    
   
    override public func update() {
        super.update()
        self.usernameField.delegate = self
        self.usernameLabel.textColor = UIColor.darkTextColor()
        if let value: Dictionary<String, String> = self.rowDescriptor!.value as? Dictionary<String, String> {
            if let username = value[OTRUsernameCell.UsernameKey] {
                if count(username) > 0 {
                    self.usernameField.typedText = username
                }
            }
            if let domain = value[OTRUsernameCell.DomainKey] {
                if count(domain) > 0 {
                    var parkedText = domain
                    if (domain as NSString).containsString("@") == false {
                        parkedText = "@" + domain
                    }
                    self.usernameField.parkedText = parkedText
                }
            }
        } else {
            assert(false, "Value must be a Dictionary<String, String>")
        }
    }
    
    // MARK: XLFormDescriptorCell
    
    override public static func formDescriptorCellHeightForRowDescriptor(rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 43
    }
    
    override public func formDescriptorCellCanBecomeFirstResponder() -> Bool {
        return !self.rowDescriptor.isDisabled()
    }
    
    override public func formDescriptorCellBecomeFirstResponder() -> Bool {
        self.highlight()
        return self.usernameField.becomeFirstResponder()
    }
    
    // MARK: UITextFieldDelegate
    
    public func textFieldShouldClear(textField: UITextField) -> Bool {
        return self.formViewController().textFieldShouldClear(textField)
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        return self.formViewController().textFieldShouldReturn(textField)
    }
    
    public func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return self.formViewController().textFieldShouldBeginEditing(textField)
    }
    
    public func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return self.formViewController().textFieldShouldEndEditing(textField)
    }
    
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return self.formViewController().textField(textField, shouldChangeCharactersInRange: range, replacementString: string)
    }
   
    public func textFieldDidBeginEditing(textField: UITextField) {
        self.formViewController().beginEditing(self.rowDescriptor)
        self.formViewController().textFieldDidBeginEditing(textField)
    }
    
    public func textFieldDidEndEditing(textField: UITextField) {
        self.textFieldValueChanged(self.usernameField)
        self.formViewController().endEditing(self.rowDescriptor)
        self.formViewController().textFieldDidEndEditing(textField)
    }
    
    // MARK: UITextField value changes
    
    @IBAction func textFieldValueChanged(sender: ParkedTextField) {
        let value = OTRUsernameCell.createRowDictionaryValueForUsername(sender.typedText, domain: sender.parkedText)
        self.rowDescriptor.value = value
    }
    
    // MARK: Private methods
    
    public static func createRowDictionaryValueForUsername(username: String?, domain: String?) -> Dictionary<String, String> {
        var unwrappedUsername = username ?? ""
        var unwrappedDomain = domain ?? ""
        let value: Dictionary<String, String> = [OTRUsernameCell.UsernameKey: unwrappedUsername, OTRUsernameCell.DomainKey: unwrappedDomain]
        return value
    }
    
}
