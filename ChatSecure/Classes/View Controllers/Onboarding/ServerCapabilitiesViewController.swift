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
        for identifier in [ServerCapabilityTableViewCell.cellIdentifier(), PushAccountTableViewCell.cellIdentifier(), SingleButtonTableViewCell.cellIdentifier(), TwoButtonTableViewCell.cellIdentifier()] {
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
            guard let push = pushInfo else {
                // shows loading cell
                return 1
            }
            if !push.pushPermitted {
                // insert push permission cell
                return 3
            }
            // show reset and info
            return 2
        case .Server:
            return capabilities.count
        }
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch tableSections[indexPath.section] {
        case .Push:
            let emptyCell = UITableViewCell()
            // Configure the main push account info cell
            if indexPath.row == 0 {
                guard let pushCell = tableView.dequeueReusableCellWithIdentifier(PushAccountTableViewCell.cellIdentifier(), forIndexPath: indexPath) as? PushAccountTableViewCell else {
                        return emptyCell
                }
                pushCell.setPushInfo(pushInfo, pushCapabilities: capabilities[.XEP0357])
                pushCell.infoButtonBlock = {(cell, sender) in
                    self.pushInfo?.pushAPIURL.promptToShowURLFromViewController(self, sender: sender)
                }
                return pushCell
            }
            guard let push = pushInfo else {
                return emptyCell
            }
            if indexPath.row == 1 {
                // Configure the account reset/deactivate cell
                guard let resetCell = tableView.dequeueReusableCellWithIdentifier(TwoButtonTableViewCell.cellIdentifier(), forIndexPath: indexPath) as? TwoButtonTableViewCell else {
                    return emptyCell
                }
                resetCell.leftButton.setTitle("Reset", forState: .Normal)
                resetCell.leftButton.setTitleColor(UIColor.redColor(), forState: .Normal)
                resetCell.leftAction = {(cell, sender) in
                    // TODO: show reset prompt
                }
                resetCell.rightButton.setTitle("Deactivate", forState: .Normal)
                resetCell.rightButton.setTitleColor(UIColor.redColor(), forState: .Normal)
                resetCell.rightAction = {(cell, sender) in
                    // TODO: show deactivate prompt
                }
            } else if !push.pushPermitted && indexPath.row == 2 {
                guard let permissionCell = tableView.dequeueReusableCellWithIdentifier(SingleButtonTableViewCell.cellIdentifier(), forIndexPath: indexPath) as? SingleButtonTableViewCell else {
                    return emptyCell
                }
                permissionCell.button.setTitle("Fix Permissions...", forState: .Normal)
                permissionCell.buttonAction = {(cell, sender) in
                    // TODO: prompt to fix permissions
                }
                return permissionCell
            }
            
            
            return emptyCell // hopefully never get here
        case .Server:
            guard let cell = tableView.dequeueReusableCellWithIdentifier(ServerCapabilityTableViewCell.cellIdentifier(), forIndexPath: indexPath) as? ServerCapabilityTableViewCell else {
                return UITableViewCell()
            }
            var cellInfo = capabilitiesArray[indexPath.row]
            if let pushInfo = pushInfo {
                // If push account isnt working, show a warning here
                if cellInfo.code == .XEP0357 && !pushInfo.pushMaybeWorks() && cellInfo.status == .Available {
                    cellInfo = cellInfo.copy() as! ServerCapabilityInfo
                    cellInfo.status = .Warning
                }
            }
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
            if indexPath.row == 0 {
                return 140
            } else {
                return 44
            }
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
