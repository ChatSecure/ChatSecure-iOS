//
//  MigratedBuddyHeaderView.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-04-19.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit

open class MigratedBuddyHeaderView: UIView {
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var descriptionLabel: UILabel!
    @IBOutlet public var switchButton: UIButton!
    @IBOutlet public var ignoreButton: UIButton!
    @objc public var forwardingJID: XMPPJID?
    
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
