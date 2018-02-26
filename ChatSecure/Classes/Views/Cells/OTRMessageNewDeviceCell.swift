//
//  OTRMessageNewDeviceCell.swift
//  ChatSecureCore
//
//  Created by N-Pex on 2018-01-10.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

@objc open class OTRMessagesNewDeviceCell: UICollectionReusableView {
    @objc public static let reuseIdentifier = "newDeviceCell"
    
    @objc @IBOutlet open weak var titleLabel:UILabel!
    
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
    
    @objc open func populate(buddy:OTRXMPPBuddy) {
    }
}
