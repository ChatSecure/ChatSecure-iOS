//
//  EnablePushViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/4/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit

public class EnablePushViewController: UIViewController {
    
    /** Set this if you want to show OTRInviteViewController after push registration */
    public var account: OTRAccount?
    private var userLaunchedToSettings: Bool = false

    @IBOutlet weak var enablePushButton: UIButton!
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self.navigationItem.setHidesBackButton(false, animated: animated)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if userLaunchedToSettings && OTRNotificationPermissions.canSendNotifications() {
            PushController.setPushPreference(.Enabled)
            showNextScreen()
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EnablePushViewController.didRegisterUserNotificationSettings(_:)), name: OTRUserNotificationsChanged, object: nil)
    }
    
    @IBAction func enablePushPressed(sender: AnyObject) {
        PushController.registerForPushNotifications()
    }

    @IBAction func skipButtonPressed(sender: AnyObject) {
        PushController.setPushPreference(.Disabled)
        showNextScreen()
    }
    
    func showNextScreen() {
        if self.account != nil {
            
            let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate
            var inviteVC:OTRInviteViewController? = nil
            if let c = appDelegate?.theme.inviteViewControllerClass() as? OTRInviteViewController.Type {
                inviteVC = c.init()
                inviteVC!.account = self.account
                self.navigationController?.pushViewController(inviteVC!, animated: true)
            }
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
    func didRegisterUserNotificationSettings(notification: NSNotification) {
        if OTRNotificationPermissions.canSendNotifications() {
            PushController.setPushPreference(.Enabled)
            showNextScreen()
        } else {
            let alert = UIAlertController(title: OTRLanguageManager.translatedString("Enable Push in Settings"), message: nil, preferredStyle: .Alert)
            let settingsAction = UIAlertAction(title: OTRLanguageManager.translatedString("Settings"), style: .Default, handler: { (action: UIAlertAction) -> Void in
                let appSettings = NSURL(string: UIApplicationOpenSettingsURLString)
                UIApplication.sharedApplication().openURL(appSettings!)
            })
            let cancelAction = UIAlertAction(title: OTRLanguageManager.translatedString("Cancel"), style: .Cancel, handler: nil)
            alert.addAction(settingsAction)
            alert.addAction(cancelAction)
            presentViewController(alert, animated: true, completion: nil)
        }
    }

}
