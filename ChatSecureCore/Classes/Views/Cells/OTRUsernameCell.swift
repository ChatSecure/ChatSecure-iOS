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
import OTRAssets

open class OTRUsernameValidator: NSObject, XLFormValidatorProtocol {
    open func isValid(_ row: XLFormRowDescriptor!) -> XLFormValidationStatus! {
        var isValid = false
        if let value = row.value as? String {
            let (username, domain) = OTRUsernameCell.splitJID(value)
            if username.count > 0 && domain.count > 0 {
                isValid = true
            }
        }
        let status: XLFormValidationStatus = XLFormValidationStatus(msg: "", status: isValid, rowDescriptor: row)
        return status
    }
}

@objc(OTRUsernameCell)
open class OTRUsernameCell: XLFormBaseCell, UITextFieldDelegate {

    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var usernameField: ParkedTextField!
    
    deinit {
        self.usernameField.delegate = nil
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.usernameField.delegate = self
    }
    
    // MARK: XLFormBaseCell overrides
    
    override open func configure() {
        super.configure()
        self.selectionStyle = UITableViewCell.SelectionStyle.none
    }
    
    
    override open func highlight() {
        super.highlight()
        self.usernameLabel.textColor = self.tintColor
    }
    
    override open func unhighlight() {
        super.unhighlight()
        self.formViewController().updateFormRow(self.rowDescriptor)
    }
    
   
    override open func update() {
        super.update()
        self.usernameField.delegate = self
        
        if #available(iOS 13.0, *) {
            self.usernameLabel.textColor = .label
        } else {
            self.usernameLabel.textColor = .darkText
        }

        if let value = self.rowDescriptor!.value as? NSString {
            let (username, domain) = OTRUsernameCell.splitJID(value as String)
            if username.count > 0 {
                self.usernameField.typedText = username
            }
            if domain.count > 0 {
                self.usernameField.parkedText = "@" + domain
            }
        }
    }
    
    // MARK: XLFormDescriptorCell
    
    override open class func formDescriptorCellHeight(for rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 43
    }
    
    override open func formDescriptorCellCanBecomeFirstResponder() -> Bool {
        return !self.rowDescriptor!.isDisabled()
    }
    
    override open func formDescriptorCellBecomeFirstResponder() -> Bool {
        self.highlight()
        return self.usernameField.becomeFirstResponder()
    }
    
    // MARK: UITextFieldDelegate
    
    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return self.formViewController().textFieldShouldClear(textField)
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.formViewController().textFieldShouldReturn(textField)
    }
    
    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return self.formViewController().textFieldShouldBeginEditing(textField)
    }
    
    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return self.formViewController().textFieldShouldEndEditing(textField)
    }
    
    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return self.formViewController().textField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
   
    open func textFieldDidBeginEditing(_ textField: UITextField) {
        self.formViewController().beginEditing(self.rowDescriptor)
        self.formViewController().textFieldDidBeginEditing(textField)
    }
    
    open func textFieldDidEndEditing(_ textField: UITextField) {
        self.textFieldValueChanged(self.usernameField)
        self.formViewController().endEditing(self.rowDescriptor)
        self.formViewController().textFieldDidEndEditing(textField)
    }
    
    // MARK: UITextField value changes
    
    @IBAction func textFieldValueChanged(_ sender: ParkedTextField) {
        let value = sender.typedText + sender.parkedText
        rowDescriptor?.value = value
    }
    
    // MARK: Private methods
    
    
    fileprivate static func splitJID(_ jid: String) -> (username: String, domain: String) {
        let value = jid as NSString
        var username: String = ""
        var domain: String = ""
        if value.contains("@") {
            let components = value.components(separatedBy: "@")
            username = components.first ?? ""
            domain = components.last ?? ""
        } else {
            domain = value as String
        }
        return (username, domain)
    }
    
}
