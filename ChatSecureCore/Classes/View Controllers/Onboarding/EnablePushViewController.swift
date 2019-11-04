//
//  EnablePushViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/4/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRAssets
import MBProgressHUD

open class EnablePushViewController: UIViewController {
    
    /** Set this if you want to show OTRInviteViewController after push registration */
    @objc open var account: OTRAccount?
    private var hud: MBProgressHUD?

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
        PushController.canReceivePushNotifications(completion: { (enabled) in
            if enabled {
                PushController.setPushPreference(.enabled)
                self.showNextScreen()
            }
        })
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(EnablePushViewController.didRegisterUserNotificationSettings(_:)), name: NSNotification.Name(rawValue: OTRUserNotificationsChanged), object: nil)
        self.skipButton?.setTitle(SKIP_STRING(), for: .normal)
        self.enablePushButton?.setTitle(ENABLE_PUSH_STRING(), for: .normal)
        self.skipButton?.accessibilityIdentifier = "EnablePushViewSkipButton"
    }
    
    @IBAction func enablePushPressed(_ sender: AnyObject) {
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        PushController.setPushPreference(.enabled)
        PushController.registerForPushNotifications()
    }

    @IBAction func skipButtonPressed(_ sender: AnyObject) {
        PushController.setPushPreference(.disabled)
        showNextScreen()
    }
    
    func showNextScreen() {
        if let account = account {
            let inviteVC = GlobalTheme.shared.inviteViewController(account: account)
            self.navigationController?.pushViewController(inviteVC, animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func didRegisterUserNotificationSettings(_ notification: Notification) {
        PushController.canReceivePushNotifications() {
            if $0 {
                self.showNextScreen()
            } else if let view = self.view {
                self.showPromptForSystemSettings(sender: view)
            }
        }
    }

}
