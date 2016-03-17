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
        if let value = row.value as? String {
            let (username, domain) = OTRUsernameCell.splitJID(value)
            if username.characters.count > 0 && domain.characters.count > 0 {
                isValid = true
            }
        }
        let status: XLFormValidationStatus = XLFormValidationStatus(msg: "", status: isValid, rowDescriptor: row)
        return status
    }
}

@objc(OTRUsernameCell)
public class OTRUsernameCell: XLFormBaseCell, UITextFieldDelegate {

    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var usernameField: ParkedTextField!
    
    public static let kOTRFormRowDescriptorTypeUsername = "kOTRFormRowDescriptorTypeUsername"
    
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
            .setObject("OTRResources.bundle/OTRUsernameCell",
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
        
        if let value = self.rowDescriptor!.value as? NSString {
            let (username, domain) = OTRUsernameCell.splitJID(value as String)
            if username.characters.count > 0 {
                self.usernameField.typedText = username
            }
            if domain.characters.count > 0 {
                self.usernameField.parkedText = "@" + domain
            }
        }
    }
    
    // MARK: XLFormDescriptorCell
    
    override public static func formDescriptorCellHeightForRowDescriptor(rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 43
    }
    
    override public func formDescriptorCellCanBecomeFirstResponder() -> Bool {
        return !self.rowDescriptor!.isDisabled()
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
        let value = sender.typedText + sender.parkedText
        rowDescriptor?.value = value
    }
    
    // MARK: Private methods
    
    
    private static func splitJID(jid: String) -> (username: String, domain: String) {
        let value = jid as NSString
        var username: String = ""
        var domain: String = ""
        if value.containsString("@") {
            let components = value.componentsSeparatedByString("@")
            username = components.first ?? ""
            domain = components.last ?? ""
        } else {
            domain = value as String
        }
        return (username, domain)
    }
    
}
