//
//  OTRBuddyInfoCheckableCell.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-08-16.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import XLForm
import ParkedTextField
import OTRAssets

@objc(OTRBuddyInfoCheckableCell)
open class OTRBuddyInfoCheckableCell: OTRBuddyInfoCell {

    static let checkViewSize:CGFloat = 20.0
    var checkView: UIImageView!
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        checkView = UIImageView(forAutoLayout: ())
        checkView.isHidden = true
        checkView.backgroundColor = UIColor.white
        checkView.layer.borderWidth = 3
        checkView.layer.borderColor = UIColor.white.cgColor
        checkView.layer.cornerRadius = OTRBuddyInfoCheckableCell.checkViewSize / 2
        checkView.image = OTRImages.checkmark(with: UIColor.black).withRenderingMode(.alwaysTemplate)
        self.contentView.addSubview(checkView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCheckImage(image:UIImage?) {
        checkView.image = image
    }
    
    func setChecked(checked:Bool) {
        checkView.isHidden = !checked
    }
    
    open override func updateConstraints() {
        checkView.autoPinEdge(.bottom, to: .bottom, of: avatarImageView, withOffset: 0)
        checkView.autoPinEdge(.right, to: .right, of: avatarImageView, withOffset: 0)
        checkView.autoSetDimension(.height, toSize: OTRBuddyInfoCheckableCell.checkViewSize)
        checkView.autoSetDimension(.width, toSize: OTRBuddyInfoCheckableCell.checkViewSize)
        super.updateConstraints()
    }
}
