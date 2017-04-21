//
//  MigrationInfoHeaderView.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-04-17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit

public class MigrationInfoHeaderView: UIView {
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var descriptionLabel: UILabel!
    @IBOutlet public var startButton: UIButton!
    public var account: OTRXMPPAccount?
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.width
        descriptionLabel.preferredMaxLayoutWidth = descriptionLabel.bounds.width
    }
}
