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
    
    public static let CellIdentifier = "ServerCapabilityTableViewCell"
    
    public var infoButtonBlock: ((cell: ServerCapabilityTableViewCell, sender: AnyObject) -> ())?
    
    public func setCapability(capability: ServerCapabilityInfo) {
        var check = "❔"
        switch capability.status {
        case .Available:
            check = "✅"
            break
        case .Unavailable:
            check = "❌"
            break
        default:
            check = "❔"
        }
        self.checkLabel.text = check
        self.titleLabel.text = capability.title
        self.subtitleLabel.text = capability.subtitle
    }

    @IBAction func infoButtonPressed(sender: AnyObject) {
        guard let block = infoButtonBlock else { return }
        block(cell: self, sender: sender)
    }
}
