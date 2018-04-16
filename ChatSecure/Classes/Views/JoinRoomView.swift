//
//  JoinRoomView.swift
//  ChatSecure
//
//  Created by N-Pex on 2018-04-11.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import UIKit

open class JoinRoomView: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    
    open var acceptButtonCallback:(() -> Void)?
    open var declineButtonCallback:(() -> Void)?
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = GlobalTheme.shared.mainThemeColor
        // Initialization code
    }
    
    open override var canBecomeFirstResponder: Bool {
        return true
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.acceptButton.layer.cornerRadius = self.acceptButton.frame.height / 2
    }
    
    @IBAction func joinRoomAccept(sender: AnyObject) {
        if let callback = self.acceptButtonCallback {
            callback()
        }
    }
    
    @IBAction func joinRoomDecline(sender: AnyObject) {
        if let callback = self.declineButtonCallback {
            callback()
        }
    }
}
