//
//  MaybeLaterViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 5/8/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRAssets
import UserVoice
import Appirater

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
        let itemProvider = OTRActivityItemProvider(placeholderItem: "")
        let qr = OTRQRCodeActivity()
        let avc = UIActivityViewController(activityItems: [itemProvider], applicationActivities: [qr])
        avc.excludedActivityTypes = [.print, .assignToContact, .saveToCameraRoll]
        avc.setPopoverSource(sender)
        present(avc, animated: true, completion: nil)
    }
    
    @IBAction func translateButtonPressed(_ sender: Any) {
        prompt(toShow: OTRBranding.transifexURL, sender: sender)
    }
    
    @IBAction func joinBetaPressed(_ sender: Any) {
        prompt(toShow: OTRBranding.testflightSignupURL, sender: sender)
    }
    
    @IBAction func submitIdeasPressed(_ sender: Any) {
        let alert = UIAlertController(title: SHOW_USERVOICE_STRING(), message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: CANCEL_STRING(), style: .cancel, handler: nil);
        let show = UIAlertAction(title: OK_STRING(), style: .default) { (action) in
            let config = UVConfig(site: OTRBranding.userVoiceSite!)
            UserVoice.presentInterface(forParentViewController: self, andConfig: config)
        }
        alert.addAction(cancel)
        alert.addAction(show)
        alert.setPopoverSource(sender)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func reviewButtonPressed(_ sender: Any) {
        Appirater.rateApp()
    }

    @IBAction func fileBugPressed(_ sender: Any) {
        let url = OTRBranding.githubURL.appendingPathComponent("issues")
        prompt(toShow: url, sender: sender)
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

fileprivate extension UIViewController {
    func setPopoverSource(_ sender: Any) {
        if let view = sender as? UIView {
            popoverPresentationController?.sourceView = view
            popoverPresentationController?.sourceRect = view.bounds
        }
    }
}
