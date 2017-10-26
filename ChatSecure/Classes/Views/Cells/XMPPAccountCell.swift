//
//  XMPPAccountCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 3/3/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit

public typealias CellButtonBlock = (_ cell: UITableViewCell, _ sender: Any) -> ()

@objc(XMPPAccountCell)
public class XMPPAccountCell: UITableViewCell {
    @IBOutlet weak var avatarButton: UIButton!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet public weak var accountNameLabel: UILabel!
    @IBOutlet public weak var infoButton: UIButton!
    
    @objc public var infoButtonAction: CellButtonBlock?
    @objc public var avatarButtonAction: CellButtonBlock?
    
    @objc public class func cellIdentifier() -> String {
        return "XMPPAccountCell"
    }
    
    @objc public class func cellHeight() -> CGFloat {
        return 80
    }
    
    public override func awakeFromNib() {
        avatarButton.backgroundColor = nil
    }
    
    @objc public func setAppearance(buddy: OTRBuddy) {
        setAppearance(userInfo: buddy)
    }

    @objc public func setAppearance(account: OTRXMPPAccount) {
        setAppearance(userInfo: account)
    }
    
    func setAppearance(userInfo: OTRUserInfoProfile) {
        let image = userInfo.avatarImage
        avatarButton.setImage(image, for: .normal)
        
        if let imageView = avatarButton.imageView {
            setAppearance(userInfo: userInfo, usernameLabel: accountNameLabel, displayNameLabel: displayNameLabel, avatarImageView: imageView)
        }
    }
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        guard let block = infoButtonAction else { return }
        block(self, sender)
    }
    
    @IBAction func avatarButtonPressed(_ sender: Any) {
        guard let block = avatarButtonAction else { return }
        block(self, sender)
    }
}
