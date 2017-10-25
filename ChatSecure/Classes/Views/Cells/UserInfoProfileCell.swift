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
open class UserInfoProfileCell: XLFormBaseCell {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    open override func update() {
        super.update()
        guard let userInfo = rowDescriptor.value as? OTRUserInfoProfile else {
            return
        }
        setAppearance(userInfo: userInfo, usernameLabel: usernameLabel, displayNameLabel: displayNameLabel, avatarImageView: avatarImageView)
    }
    
    open override class func formDescriptorCellHeight(for rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 90
    }
    
}

extension UITableViewCell {
    func setAppearance(userInfo: OTRUserInfoProfile, usernameLabel: UILabel, displayNameLabel: UILabel, avatarImageView: UIImageView) {
        var displayName = userInfo.displayName
        if let userInfo = userInfo as? OTRThreadOwner {
            displayName = userInfo.threadName
        }
        usernameLabel.text = userInfo.username
        displayNameLabel.text = displayName
        avatarImageView.image = userInfo.avatarImage
        avatarImageView.layer.cornerRadius = avatarImageView.frame.height/2
        avatarImageView.layer.masksToBounds = true
        if let avatarBorderColor = userInfo.avatarBorderColor {
            avatarImageView.layer.borderWidth = 1.5
            avatarImageView.layer.borderColor = avatarBorderColor.cgColor
        } else {
            avatarImageView.layer.borderWidth = 0
        }
    }
}
