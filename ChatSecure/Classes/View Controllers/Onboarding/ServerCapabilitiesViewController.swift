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
    public var serverCapabilitiesModule: OTRServerCapabilities?
    /// You must set this before showing view
    public var pushController: PushController?

    private lazy var capabilities: [CapabilityCode : ServerCapabilityInfo] = {
        return ServerCapabilityInfo.allCapabilities()
    }()
    private lazy var capabilitiesArray: [ServerCapabilityInfo] = {
        return Array(self.capabilities.values) // TODO: sort
    }()
    private var pushInfo: PushInfo?
    private let tableSections: [TableSection] = [.Push, .Server]
    
    /// Updates account information for push notifications
    private func refreshPushInfo() {
        guard let push = pushController else { return }
        push.gatherPushInfo({ (pushInfo) in
            self.pushInfo = pushInfo
            self.tableView.reloadData()
            }, callbackQueue: dispatch_get_main_queue())
    }
    
    // MARK: User Interaction
    
    @objc private func doneButtonPressed(sender: AnyObject?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: View Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let bundle = OTRAssets.resourcesBundle()
        for identifier in [ServerCapabilityTableViewCell.cellIdentifier(), PushAccountTableViewCell.cellIdentifier()] {
            let nib = UINib(nibName: identifier, bundle: bundle)
            tableView.registerNib(nib, forCellReuseIdentifier: identifier)
        }

        tableView.allowsSelection = false
        
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
        refreshPushInfo()
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if let caps = serverCapabilitiesModule {
            caps.removeDelegate(self)
        }
    }
    
    // MARK: UITableViewDataSource
    
    public override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableSections[section] {
        case .Push:
            return CHATSECURE_PUSH_STRING()
        case .Server:
            return Server_String()
        }
    }
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableSections.count
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableSections[section] {
        case .Push:
            return 1
        case .Server:
            return capabilities.count
        }
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch tableSections[indexPath.section] {
        case .Push:
            guard let cell = tableView.dequeueReusableCellWithIdentifier(PushAccountTableViewCell.cellIdentifier(), forIndexPath: indexPath) as? PushAccountTableViewCell,
                let xmppPush = capabilities[.XEP0357] else {
                return UITableViewCell()
            }
            cell.setPushInfo(pushInfo, pushCapabilities: xmppPush)
            cell.infoButtonBlock = {(cell, sender) in
                self.pushInfo?.pushAPIURL.promptToShowURLFromViewController(self, sender: sender)
            }
            return cell
        case .Server:
            guard let cell = tableView.dequeueReusableCellWithIdentifier(ServerCapabilityTableViewCell.cellIdentifier(), forIndexPath: indexPath) as? ServerCapabilityTableViewCell else {
                return UITableViewCell()
            }
            let cellInfo = capabilitiesArray[indexPath.row]
            cell.setCapability(cellInfo)
            cell.infoButtonBlock = {(cell, sender) in
                cellInfo.url.promptToShowURLFromViewController(self, sender: sender)
            }
            return cell
        }
    }
    
    public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch tableSections[indexPath.section] {
        case .Push:
            return 140
        case .Server:
            return 91
        }
    }
    
    // MARK: OTRServerCapabilitiesDelegate
    
    @objc public func serverCapabilities(sender: OTRServerCapabilities, didDiscoverAllCapabilities allCapabilities: [XMPPJID : DDXMLElement]) {
        guard let caps = serverCapabilitiesModule else { return }
        capabilities = ServerCapabilityInfo.markAvailable(capabilities, serverCapabilitiesModule: caps)
        tableView.reloadData()
    }
    
    // MARK: Cell Data
    
    private enum TableSection: UInt {
        case Push
        case Server
    }

}
