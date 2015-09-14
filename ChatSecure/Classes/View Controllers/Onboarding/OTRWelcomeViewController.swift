//
//  OTRWelcomeViewController.swift
//  ChatSecure
//
//  Created by Christopher Ballinger on 8/6/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

import UIKit

public class OTRWelcomeViewController: UIViewController {
    
    public var completionBlock: ((account: OTRAccount!, error: NSError!) -> Void)?
    
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

        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "createNewAccountSegue" {
            let createAccountVC: OTRBaseLoginViewController = segue.destinationViewController as! OTRBaseLoginViewController
            let newAccount = OTRXMPPAccount(accountType: OTRAccountType.Jabber)
            createAccountVC.form = OTRXLFormCreator.formForAccountType(newAccount.accountType, createAccount: true)
            createAccountVC.createLoginHandler = OTRXMPPCreateAccountHandler()
            createAccountVC.account = newAccount
            createAccountVC.completionBlock = self.completionBlock
        }
    }
    
    @IBAction func skipButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
