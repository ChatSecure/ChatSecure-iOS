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
    public var buttonAction: ((_ cell: SingleButtonTableViewCell, _ sender: UIButton) -> ())?

    public class func cellIdentifier() -> String {
        return "SingleButtonTableViewCell"
    }
    
    @IBAction private func buttonPressed(_ sender: UIButton) {
        guard let action = buttonAction else { return }
        action(self, sender)
    }
}
