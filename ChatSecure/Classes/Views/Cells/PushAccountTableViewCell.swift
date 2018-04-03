//
//  PushAccountTableViewCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/12/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit

@objc(PushAccountTableViewCell)
public class PushAccountTableViewCell: ServerCapabilityTableViewCell {
    
    @IBOutlet weak var extraDataLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    public override class func cellIdentifier() -> String {
        return "PushAccountTableViewCell"
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        extraDataLabel.text = nil
        activityIndicator.stopAnimating()
    }
    
    //FIXME: unlocalized strings
    
    /// pushCapabilities must be for code == .XEP0357
    public func setPushInfo(pushInfo: PushInfo?, pushCapabilities: ServerCapabilityInfo?, pushStatus: XMPPPushStatus) {
        var xep0357 = false
        if let caps = pushCapabilities, caps.code == .XEP0357 && caps.status == .Available {
            xep0357 = true
        }
        
        // Common Setup
        titleLabel.text = "Push Registration"
        extraDataLabel.textColor = UIColor.lightGray
        
        // Loading Indicator
        guard let push = pushInfo else {
            extraDataLabel.text = "Loading..."
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            checkLabel.text = ""
            subtitleLabel.text = ""
            return
        }
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        
        // Push Info
        var checkmark = "❓"
        var status = "Inactive"
        if  push.pushMaybeWorks() &&
            xep0357 {
            checkmark = "✅"
            status = "Active"
        } else if (!push.pushOptIn) {
            checkmark = "❌"
            status = "Inactive"
        } else if (!push.pushPermitted) {
            checkmark = "❌"
            status = "Push Permission Disabled" // prompt user to fix
        } else if (!push.backgroundFetchPermitted) {
            checkmark = "❌"
            status = "Background Fetch Disabled" // prompt user to fix
        } else if (!push.hasPushAccount) {
            checkmark = "❌"
            status = "Not Registered"
        } else if (push.device == nil) {
            checkmark = "⚠️"
            status = "Device Not Registered"
        } else if (!xep0357) {
            checkmark = "⚠️"
            status = "XMPP Server Incompatible (see XEP-0357)"
        } else if (push.numUsedTokens == 0) {
            checkmark = "⚠️"
            // this means no tokens have been uploaded to a xmpp server
            // or distributed to a buddy.
            status = "No Used Tokens"
        } else if (pushStatus != .registered) {
            checkmark = "⚠️"
            // this will happen if the server supports push
            // but there was an error during registration
            status = "XMPP Server Error (see XEP-0357)"
        } else if (push.lowPowerMode) {
            checkmark = "⚠️"
            status = "Turn Off Low Power Mode"
        } else {
            checkmark = "❌"
            status = "Unknown Error"
        }
        titleLabel.text = "Push Registration"
        subtitleLabel.text = "" + status
        let apiEndpoint = String(format: "%@%@", push.pushAPIURL.host ?? "", push.pushAPIURL.path)
        extraDataLabel.text = String(format: "%@\n%@\n%d used, %d unused tokens", apiEndpoint, push.pubsubEndpoint ?? "Error", push.numUsedTokens, push.numUnusedTokens)
        checkLabel.text = checkmark
    }
}
