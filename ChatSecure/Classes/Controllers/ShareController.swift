//
//  ShareController.swift
//  ChatSecure
//
//  Created by Christopher Ballinger on 9/25/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import UIKit

public class ShareController: NSObject {
    public static func shareAccount(account: OTRAccount, sender: AnyObject, viewController: UIViewController) {
        let url = NSURL.otr_shareLink(NSURL.otr_shareBaseURL().absoluteString, username: account.username, fingerprint: nil, base64Encoded: true)
        let qrCodeActivity = OTRQRCodeActivity()
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: [qrCodeActivity])
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList]
        
        if let cell = sender as? UITableViewCell {
            if let ppc = activityViewController.popoverPresentationController {
                ppc.sourceView = cell
                ppc.sourceRect = cell.bounds
            }
        }
        viewController.presentViewController(activityViewController, animated: true, completion: nil)
    }
}
