//
//  EnablePushViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/4/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRAssets

open class EnablePushViewController: UIViewController {
    
    /** Set this if you want to show OTRInviteViewController after push registration */
    open var account: OTRAccount?
    fileprivate var userLaunchedToSettings: Bool = false

    @IBOutlet weak var enablePushButton: UIButton?
    @IBOutlet weak var textView: UITextView?
    @IBOutlet weak var skipButton: UIButton?
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.navigationItem.setHidesBackButton(false, animated: animated)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if userLaunchedToSettings && PushController.canReceivePushNotifications() {
            PushController.setPushPreference(.enabled)
            showNextScreen()
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(EnablePushViewController.didRegisterUserNotificationSettings(_:)), name: NSNotification.Name(rawValue: OTRUserNotificationsChanged), object: nil)
        self.skipButton?.setTitle(SKIP_STRING(), for: UIControlState())
        self.enablePushButton?.setTitle(ENABLE_PUSH_STRING(), for: UIControlState())
        self.skipButton?.accessibilityIdentifier = "EnablePushViewSkipButton"
    }
    
    @IBAction func enablePushPressed(_ sender: AnyObject) {
        PushController.registerForPushNotifications()
    }

    @IBAction func skipButtonPressed(_ sender: AnyObject) {
        PushController.setPushPreference(.disabled)
        showNextScreen()
    }
    
    func showNextScreen() {
        if self.account != nil {
            
            let appDelegate = UIApplication.shared.delegate as? OTRAppDelegate
            var inviteVC:OTRInviteViewController? = nil
            if let c = appDelegate?.theme.inviteViewControllerClass() as? OTRInviteViewController.Type {
                inviteVC = c.init()
                inviteVC!.account = self.account
                self.navigationController?.pushViewController(inviteVC!, animated: true)
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func didRegisterUserNotificationSettings(_ notification: Notification) {
        if PushController.canReceivePushNotifications() {
            PushController.setPushPreference(.enabled)
            showNextScreen()
        } else {
            let alert = UIAlertController(title: ENABLE_PUSH_IN_SETTINGS_STRING(), message: nil, preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: SETTINGS_STRING(), style: .default, handler: { (action: UIAlertAction) -> Void in
                let appSettings = URL(string: UIApplicationOpenSettingsURLString)
                UIApplication.shared.openURL(appSettings!)
            })
            let cancelAction = UIAlertAction(title: CANCEL_STRING(), style: .cancel, handler: nil)
            alert.addAction(settingsAction)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
    }

}
