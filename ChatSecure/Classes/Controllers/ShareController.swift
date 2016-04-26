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
        let fingerprintTypes = Set([NSNumber(int: OTRFingerprintType.OTR.rawValue)])
        
        account.generateShareURLWithFingerprintTypes(fingerprintTypes, completion: { (url: NSURL!, error: NSError!) -> Void in
            let qrCodeActivity = OTRQRCodeActivity()
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: [qrCodeActivity])
            activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList]
            if let ppc = activityViewController.popoverPresentationController {
                if let view = sender as? UIView {
                    ppc.sourceView = view
                    ppc.sourceRect = view.bounds
                }
            }
            
            viewController.presentViewController(activityViewController, animated: true, completion: nil)
        })
        
    }
}
