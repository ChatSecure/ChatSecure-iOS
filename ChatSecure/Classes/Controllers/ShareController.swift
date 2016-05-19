//
//  ShareController.swift
//  ChatSecure
//
//  Created by Christopher Ballinger on 9/25/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import UIKit

public class ShareControllerURLSource: NSObject, UIActivityItemSource {
    public var account: OTRAccount?
    public var url:NSURL?
    
    public init(account: OTRAccount, url: NSURL) {
        self.account = account
        self.url = url
    }
    
    public func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return self.url!
    }
    
    public func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        return self.url
    }
    
    public func activityViewController(activityViewController: UIActivityViewController, subjectForActivityType activityType: String?) -> String {
        var name = OTRLanguageManager.translatedString("Someone")
        if let displayName = account?.username {
            name = displayName
        }
        let chatString = OTRLanguageManager.translatedString("wants to chat.")
        let text = "\(name) \(chatString)"
        return text
    }
}

public class ShareController: NSObject {
    public static func shareAccount(account: OTRAccount, sender: AnyObject, viewController: UIViewController) {
        let fingerprintTypes = Set([NSNumber(int: OTRFingerprintType.OTR.rawValue)])
        
        account.generateShareURLWithFingerprintTypes(fingerprintTypes, completion: { (url: NSURL!, error: NSError!) -> Void in
            let qrCodeActivity = OTRQRCodeActivity()
            let activityViewController = UIActivityViewController(activityItems: [self.getShareSource(account, url: url)], applicationActivities: [qrCodeActivity])
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
    
    public static func getShareSource(account: OTRAccount, url: NSURL) -> AnyObject {
        return ShareControllerURLSource(account: account, url: url)
    }
}
