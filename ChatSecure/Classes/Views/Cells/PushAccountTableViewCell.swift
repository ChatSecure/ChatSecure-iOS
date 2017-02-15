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
    public func setPushInfo(pushInfo: PushInfo?, pushCapabilities: ServerCapabilityInfo?) {
        assert(pushCapabilities?.code == .XEP0357)
        
        // Common Setup
        titleLabel.text = "Push Registration"
        extraDataLabel.textColor = UIColor.lightGrayColor()
        
        // Loading Indicator
        guard let push = pushInfo, let caps = pushCapabilities else {
            extraDataLabel.text = "Loading..."
            activityIndicator.startAnimating()
            activityIndicator.hidden = false
            checkLabel.text = ""
            subtitleLabel.text = ""
            return
        }
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        
        // Push Info
        var checkmark = "❓"
        var status = "Inactive"
        if  push.pushMaybeWorks() &&
            caps.status == .Available {
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
        } else if (caps.status != .Available) {
            checkmark = "⚠️"
            status = "XMPP Server Incompatible (see XEP-0357)"
        } else if (push.numUsedTokens == 0) {
            checkmark = "⚠️"
            // this means no tokens have been uploaded to a xmpp server
            // or distributed to a buddy.
            status = "No Used Tokens"
        } else if (push.lowPowerMode) {
            checkmark = "⚠️"
            status = "Turn Off Low Power Mode"
        } else {
            checkmark = "❌"
            status = "Unknown Error"
        }
        titleLabel.text = "Push Registration"
        subtitleLabel.text = "" + status
        let apiEndpoint = String(format: "%@%@", push.pushAPIURL.host ?? "", push.pushAPIURL.path ?? "")
        extraDataLabel.text = String(format: "%@\n%@\n%d used, %d unused tokens", apiEndpoint, push.pubsubEndpoint ?? "Error", push.numUsedTokens, push.numUnusedTokens)
        checkLabel.text = checkmark
    }
}
