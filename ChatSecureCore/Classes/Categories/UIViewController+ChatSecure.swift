//
//  UIViewController+ChatSecure.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/16/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRAssets

extension UIViewController {
    /// Will show a prompt to bring user into system settings
    public func showPromptForSystemSettings(sender: Any) {
        let alert = UIAlertController(title: ENABLE_PUSH_IN_SETTINGS_STRING(), message: nil, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: SETTINGS_STRING(), style: .default, handler: { (action: UIAlertAction) -> Void in
            let appSettings = URL(string: UIApplication.openSettingsURLString)
            UIApplication.shared.open(appSettings!)
        })
        let cancelAction = UIAlertAction(title: CANCEL_STRING(), style: .cancel, handler: nil)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        if let sourceView = sender as? UIView {
            alert.popoverPresentationController?.sourceView = sourceView;
            alert.popoverPresentationController?.sourceRect = sourceView.bounds;
        }
        present(alert, animated: true, completion: nil)
    }
    
    public func showDestructivePrompt(title: String?, buttonTitle: String, sender: Any, handler: @escaping ((_ action: UIAlertAction) -> ())) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        let destroyAction = UIAlertAction(title: buttonTitle, style: .destructive, handler: handler)
        let cancelAction = UIAlertAction(title: CANCEL_STRING(), style: .cancel, handler: nil)
        alert.addAction(destroyAction)
        alert.addAction(cancelAction)
        if let sourceView = sender as? UIView {
            alert.popoverPresentationController?.sourceView = sourceView;
            alert.popoverPresentationController?.sourceRect = sourceView.bounds;
        }
        present(alert, animated: true, completion: nil)
    }
}
