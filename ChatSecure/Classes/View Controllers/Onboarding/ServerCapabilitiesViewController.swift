//
//  ServerCapabilitiesViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/9/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import XMPPFramework
import OTRAssets

public class ServerCapabilitiesViewController: UITableViewController, OTRServerCapabilitiesDelegate {
    
    /// You must set this before showing view
    public weak var serverCapabilitiesModule: OTRServerCapabilities?
    
    private lazy var capabilities: [ServerCapabilityInfo] = {
        return ServerCapabilityInfo.allCapabilities()
    }()
    
    // MARK: User Interaction
    
    @objc private func doneButtonPressed(sender: AnyObject?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: View Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let bundle = OTRAssets.resourcesBundle()
        let nib = UINib(nibName: ServerCapabilityTableViewCell.CellIdentifier, bundle: bundle)
        tableView.registerNib(nib, forCellReuseIdentifier: ServerCapabilityTableViewCell.CellIdentifier)
        
        self.title = Server_String()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(doneButtonPressed(_:)))
        navigationItem.rightBarButtonItem = doneButton
    }
    
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        guard let caps = serverCapabilitiesModule else { return }
        capabilities = ServerCapabilityInfo.markAvailable(capabilities, serverCapabilitiesModule: caps)
        caps.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        tableView.reloadData()
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if let caps = serverCapabilitiesModule {
            caps.removeDelegate(self)
        }
    }
    
    // MARK: UITableViewDataSource
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return capabilities.count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ServerCapabilityTableViewCell.CellIdentifier, forIndexPath: indexPath)
        let cellInfo = capabilities[indexPath.row]
        if let cell = cell as? ServerCapabilityTableViewCell {
            cell.setCapability(cellInfo)
            cell.infoButtonBlock = {(cell, sender) in
                NSLog("Show URL: %@", cellInfo.url)
            }
        }
        return cell
    }
    
    public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 91
    }
    
    // MARK: OTRServerCapabilitiesDelegate
    
    @objc public func serverCapabilities(sender: OTRServerCapabilities, didDiscoverAllCapabilities allCapabilities: [XMPPJID : DDXMLElement]) {
        guard let caps = serverCapabilitiesModule else { return }
        capabilities = ServerCapabilityInfo.markAvailable(capabilities, serverCapabilitiesModule: caps)
        tableView.reloadData()
    }
    
    
}
