//
//  ServerCapabilityTableViewCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/10/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit

@objc(ServerCapabilityTableViewCell)
public class ServerCapabilityTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var checkLabel: UILabel!
    
    /// This will also be the name of the xib
    public class func cellIdentifier() -> String {
        return "ServerCapabilityTableViewCell"
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        checkLabel.text = nil
    }
    
    public var infoButtonBlock: ((_ cell: ServerCapabilityTableViewCell, _ sender: Any) -> ())?
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        guard let block = infoButtonBlock else { return }
        block(self, sender)
    }
}

extension ServerCapabilityTableViewCell {
    public func setCapability(capability: ServerCapabilityInfo) {
        var check = "❓"
        switch capability.status {
        case .Available:
            check = "✅"
            break
        case .Unavailable:
            check = "❌"
            break
        case .Warning:
            check = "⚠️"
        default:
            check = "❓"
        }
        self.checkLabel.text = check
        self.titleLabel.text = capability.title
        self.subtitleLabel.text = capability.subtitle
    }
}
