//
//  MigratedBuddyHeaderView.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-04-19.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit

public class MigratedBuddyHeaderView: UIView {
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var descriptionLabel: UILabel!
    @IBOutlet public var switchButton: UIButton!
    @IBOutlet public var ignoreButton: UIButton!
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.width
        descriptionLabel.preferredMaxLayoutWidth = descriptionLabel.bounds.width
    }
}
