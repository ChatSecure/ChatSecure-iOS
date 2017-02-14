//
//  SingleButtonTableViewCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/14/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit

@objc(SingleButtonTableViewCell)
public class SingleButtonTableViewCell: UITableViewCell {

    @IBOutlet public weak var button: UIButton!
    public var buttonAction: ((cell: SingleButtonTableViewCell, sender: AnyObject) -> ())?

    public class func cellIdentifier() -> String {
        return "SingleButtonTableViewCell"
    }
    
    @IBAction private func buttonPressed(sender: AnyObject) {
        guard let action = buttonAction else { return }
        action(cell: self, sender: sender)
    }
}
