//
//  OTRWelcomeViewController.swift
//  ChatSecure
//
//  Created by Christopher Ballinger on 8/6/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

import UIKit

public class OTRWelcomeViewController: UIViewController {
    
    // MARK: - Views
    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var createAccountButton: UIButton!
    @IBOutlet var existingAccountButton: UIButton!
    @IBOutlet var skipButton: UIButton!
    
    // MARK: - View Lifecycle
    
    override public func viewWillAppear(animated: Bool) {
        self.navigationController!.setNavigationBarHidden(true, animated: animated)
    }
    
    override public func viewWillDisappear(animated: Bool) {
        self.navigationController!.setNavigationBarHidden(false, animated: animated)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        self.createAccountButton.setTitle(OTRLanguageManager.translatedString("Create New Account"), forState: .Normal)
        self.skipButton.setTitle(OTRLanguageManager.translatedString("Skip"), forState: .Normal)
        self.existingAccountButton.setTitle(OTRLanguageManager.translatedString("Add Existing Account"), forState: .Normal)
        
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "createNewAccountSegue" {
            let createAccountVC: OTRBaseLoginViewController = segue.destinationViewController as! OTRBaseLoginViewController
            createAccountVC.form = OTRXLFormCreator.formForAccountType(OTRAccountType.Jabber, createAccount: true)
            createAccountVC.loginHandler = OTRXMPPCreateAccountHandler()
        }
    }
    
    @IBAction func skipButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
