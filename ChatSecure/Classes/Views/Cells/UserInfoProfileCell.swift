//
//  UserInfoProfileCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 10/31/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import XLForm

@objc(UserInfoProfileCell)
public class UserInfoProfileCell: XLFormBaseCell {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    public override func update() {
        super.update()
        guard let userInfo = rowDescriptor.value as? OTRUserInfoProfile else {
            return
        }
        var displayName = userInfo.displayName
        if let userInfo = userInfo as? OTRThreadOwner {
            displayName = userInfo.threadName()
        }
        usernameLabel.text = userInfo.username
        displayNameLabel.text = displayName
        avatarImageView.image = userInfo.avatarImage
        avatarImageView.layer.cornerRadius = CGRectGetHeight(self.avatarImageView.frame)/2
        avatarImageView.layer.masksToBounds = true
        if let avatarBorderColor = userInfo.avatarBorderColor {
            self.avatarImageView.layer.borderWidth = 1.5
            self.avatarImageView.layer.borderColor = avatarBorderColor.CGColor
        } else {
            self.avatarImageView.layer.borderWidth = 0
        }
    }
    
    public override class func formDescriptorCellHeightForRowDescriptor(rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 90
    }
    
}
