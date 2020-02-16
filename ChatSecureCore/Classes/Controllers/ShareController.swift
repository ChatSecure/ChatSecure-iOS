//
//  ShareController.swift
//  ChatSecure
//
//  Created by Christopher Ballinger on 9/25/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRAssets

open class ShareControllerURLSource: NSObject, UIActivityItemSource {
    open var account: OTRAccount?
    open var url:URL?
    
    public init(account: OTRAccount, url: URL) {
        self.account = account
        self.url = url
    }
    
    open func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.url!
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.url
    }
    
    open func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        var name = SOMEONE_STRING()
        if let displayName = account?.username {
            name = displayName
        }
        let chatString = WANTS_TO_CHAT_STRING()
        let text = "\(name) \(chatString)"
        return text
    }
}

open class ShareController: NSObject {
    @objc public static func shareAccount(_ account: OTRAccount, sender: Any, viewController: UIViewController) {
        let fingerprintTypes = Set([NSNumber(value: OTRFingerprintType.OTR.rawValue as Int32)])
        
        account.generateShareURL(withFingerprintTypes: fingerprintTypes, completion: { (url: URL?, error: Error?) -> Void in
            guard let url = url else {
                return
            }
            
            let qrCodeActivity = OTRQRCodeActivity()
            let activityViewController = UIActivityViewController(activityItems: [self.getShareSource(account, url: url)], applicationActivities: [qrCodeActivity])
            activityViewController.excludedActivityTypes = [UIActivity.ActivityType.print, UIActivity.ActivityType.saveToCameraRoll, UIActivity.ActivityType.addToReadingList]
            if let ppc = activityViewController.popoverPresentationController {
                if let view = sender as? UIView {
                    ppc.sourceView = view
                    ppc.sourceRect = view.bounds
                }
            }
            
            viewController.present(activityViewController, animated: true, completion: nil)
        })
        
    }
    
    @objc public static func getShareSource(_ account: OTRAccount, url: URL) -> AnyObject {
        return ShareControllerURLSource(account: account, url: url)
    }
}
