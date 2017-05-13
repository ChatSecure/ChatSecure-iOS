//
//  MaybeLaterViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 5/8/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRAssets

public class MaybeLaterViewController: UIViewController {

    @IBOutlet weak var subheadingLabel: UILabel!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if TransactionObserver.hasValidReceipt {
            subheadingLabel.text = THANK_YOU_FOR_CONTRIBUTION()
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
    }
    
    @IBAction func translateButtonPressed(_ sender: Any) {
    }
    
    @IBAction func joinBetaPressed(_ sender: Any) {
    }
    
    @IBAction func submitIdeasPressed(_ sender: Any) {
    }
    
    @IBAction func reviewButtonPressed(_ sender: Any) {
    }

    @IBAction func fileBugPressed(_ sender: Any) {
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//        if let purchase = sender as? PurchaseViewController {
//            
//        }
//    }

}
