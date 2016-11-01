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
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public override func update() {
        super.update()
        guard let userInfo = rowDescriptor.value as? OTRUserInfoProfile else {
            return
        }
        usernameLabel.text = userInfo.username
        displayNameLabel.text = userInfo.displayName
        avatarImageView.image = userInfo.avatarImage
    }
    
    public override class func formDescriptorCellHeightForRowDescriptor(rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 90
    }
    
}
