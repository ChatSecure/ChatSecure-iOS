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

    public override class func cellIdentifier() -> String {
        return "PushAccountTableViewCell"
    }
    
    //FIXME: unlocalized strings
    
    /// pushCapabilities must be for code == .XEP0357
    public func setPushInfo(pushInfo: PushInfo, pushCapabilities: ServerCapabilityInfo) {
        assert(pushCapabilities.code == .XEP0357)
        var checkmark = "❓"
        var status = "Inactive"
        var lowPower = false
        if #available(iOS 9.0, *) {
            lowPower = NSProcessInfo.processInfo().lowPowerModeEnabled
        }
        if  pushInfo.hasPushAccount &&
            pushInfo.pushPermitted &&
            pushInfo.numUsedTokens > 0 &&
            pushCapabilities.status == .Available &&
            !lowPower {
            checkmark = "✅"
            status = "Active"
        } else if (!pushInfo.pushPermitted) {
            checkmark = "❌"
            status = "Permission Disabled" // prompt user to fix
        } else if (!pushInfo.hasPushAccount) {
            checkmark = "❌"
            status = "Not Registered"
        } else if (pushCapabilities.status != .Available) {
            checkmark = "⚠️"
            status = "XMPP Server Incompatible (see XEP-0357)"
        } else if (pushInfo.numUsedTokens == 0) {
            checkmark = "⚠️"
            // this means no tokens have been uploaded to a xmpp server
            // or distributed to a buddy.
            status = "No Used Tokens"
        } else if (lowPower) {
            checkmark = "⚠️"
            status = "Turn Off Low Power Mode"
        } else {
            checkmark = "❌"
            status = "Unknown Error"
        }
        titleLabel.text = "Push Registration"
        subtitleLabel.text = status
        let apiEndpoint = String(format: "%@%@", pushInfo.pushAPIURL.host ?? "", pushInfo.pushAPIURL.path ?? "")
        extraDataLabel.text = String(format: "Endpoint: %@\nPubsub: %@\nTokens: %d used, %d unused", apiEndpoint, pushInfo.pubsubEndpoint ?? "Error", pushInfo.numUsedTokens, pushInfo.numUnusedTokens)
        checkLabel.text = checkmark
    }
}
