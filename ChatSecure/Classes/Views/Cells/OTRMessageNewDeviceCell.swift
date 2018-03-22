//
//  OTRMessageNewDeviceCell.swift
//  ChatSecureCore
//
//  Created by N-Pex on 2018-01-10.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

@objc open class OTRMessagesNewDeviceCell: UICollectionReusableView {
    @objc public static let reuseIdentifier = "newDeviceCell"
    
    @objc @IBOutlet open weak var actionButton:UIButton!
    @objc @IBOutlet open weak var avatarImageView:UIImageView!
    @objc @IBOutlet open weak var titleLabel:UILabel!
    @objc @IBOutlet open weak var descriptionLabel:UILabel!
    @objc @IBOutlet open weak var iconLabel:UILabel!
    
    @objc open var buddyUniqueId:String?
    @objc open var actionButtonCallback:((_ buddyUniqueId:String?) -> Void)?
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        for view in subviews {
            if let label = view as? UILabel {
                if label.numberOfLines == 0 {
                    label.preferredMaxLayoutWidth = label.bounds.width
                }
            }
        }
    }
    
    @objc open func populate(buddy:OTRXMPPBuddy, actionButtonCallback:((_ buddyUniqueId:String?) -> Void)?) {
        buddyUniqueId = buddy.uniqueId
        avatarImageView.image = buddy.avatarImage
        avatarImageView.layer.cornerRadius = avatarImageView.frame.height/2
        avatarImageView.layer.masksToBounds = true
        iconLabel.backgroundColor = iconLabel.tintColor
        self.actionButtonCallback = actionButtonCallback
    }
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        iconLabel.backgroundColor = iconLabel.tintColor
    }
    
    @IBAction open func didTapActionButton(_ sender: Any) {
        if let callback = actionButtonCallback {
            callback(buddyUniqueId)
        }
    }
}
