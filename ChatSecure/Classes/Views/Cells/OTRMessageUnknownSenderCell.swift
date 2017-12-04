//
//  OTRMessageUnknownSenderCell.swift
//  ChatSecureCore
//
//  Created by N-Pex on 2017-11-27.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

@objc public class OTRMessagesUnknownSenderCell: UICollectionReusableView {
    @objc public static let reuseIdentifier = "unknownSenderCell"
    
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
}
