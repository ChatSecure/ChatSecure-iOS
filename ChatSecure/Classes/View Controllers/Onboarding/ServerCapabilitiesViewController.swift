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
        return Array(self.capabilities.values) // TODO: sort capabilities?
    }()
    private var pushInfo: PushInfo?
    private let tableSections: [TableSection] = [.Push, .Server]
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        guard let caps = serverCapabilitiesModule else { return }
        caps.removeDelegate(self)
    }
    
    // MARK: - Data Loading and Refreshing
    
    
    /// Updates account information for push notifications
    private func refreshPushInfo() {
        guard let push = pushController else { return }
        push.gatherPushInfo({ (pushInfo) in
            self.pushInfo = pushInfo
            self.tableView.reloadData()
            }, callbackQueue: dispatch_get_main_queue())
    }
    
    /// Will refresh all data for the view
    @objc private func refreshAllData() {
        guard let caps = serverCapabilitiesModule else { return }
        capabilities = ServerCapabilityInfo.markAvailable(capabilities, serverCapabilitiesModule: caps)
        tableView.reloadData()
        refreshPushInfo()
    }
    
    // MARK: - User Interaction
    
    @objc private func doneButtonPressed(sender: AnyObject?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - View Lifecycle
    
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
        
        // This will allow us to refresh the permission prompts after use changes them in background
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshAllData), name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        // Add capabilities listener
        guard let caps = serverCapabilitiesModule else { return }
        caps.addDelegate(self, delegateQueue: dispatch_get_main_queue())
    }

    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshAllData()
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if let caps = serverCapabilitiesModule {
            caps.removeDelegate(self)
        }
    }
    
    // MARK: - Cell configuration utilities
    
    /// Returns cell count in the push acount section
    private func cellCountForPushInfo(pushInfo: PushInfo?) -> Int {
        var cellCount = 1
        guard let push = pushInfo else {
            // shows loading cell
            return cellCount
        }
        if !push.pushPermitted {
            // insert push permission cell
            cellCount += 1
        }
        if !push.backgroundFetchPermitted {
            // insert background fetch cell
            cellCount += 1
        }
        // show reset/deactivate once pushInfo is loaded
        cellCount += 1
        return cellCount
    }
    
    /// Returns cell that resets or deactivates account
    private func resetCellForTableView(tableView: UITableView, indexPath: NSIndexPath, pushInfo: PushInfo) -> UITableViewCell {
        // Configure the account reset/deactivate cell
        guard let resetCell = tableView.dequeueReusableCellWithIdentifier(TwoButtonTableViewCell.cellIdentifier(), forIndexPath: indexPath) as? TwoButtonTableViewCell else {
            return UITableViewCell()
        }
        resetCell.leftButton.setTitle("Reset", forState: .Normal)
        resetCell.leftButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        resetCell.leftAction = {(cell, sender) in
            // TODO: show reset prompt
        }
        resetCell.rightButton.setTitle("Deactivate", forState: .Normal)
        resetCell.rightButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        resetCell.rightButton.setTitleColor(UIColor.lightGrayColor(), forState: .Disabled)
        resetCell.rightAction = {(cell, sender) in
            // TODO: show deactivate prompt
        }
        resetCell.rightButton.enabled = pushInfo.hasPushAccount
        return resetCell
    }
    
    /// Cell with button to prompt user to fix push permissions
    private func fixPushPermissionCellForTableView(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        guard let permissionCell = tableView.dequeueReusableCellWithIdentifier(SingleButtonTableViewCell.cellIdentifier(), forIndexPath: indexPath) as? SingleButtonTableViewCell else {
            return UITableViewCell()
        }
        permissionCell.button.setTitle("Fix Permissions...", forState: .Normal)
        permissionCell.buttonAction = {(cell, sender) in
            // TODO: prompt to fix permissions
        }
        return permissionCell
    }
    
    /// Cell with button to prompt user to fix background fetch
    private func fixBackgroundFetchCellForTableView(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        guard let fetchCell = tableView.dequeueReusableCellWithIdentifier(SingleButtonTableViewCell.cellIdentifier(), forIndexPath: indexPath) as? SingleButtonTableViewCell else {
            return UITableViewCell()
        }
        fetchCell.button.setTitle("Fix Background Fetch...", forState: .Normal)
        fetchCell.buttonAction = {(cell, sender) in
            // TODO: prompt to fix background fetch
        }
        return fetchCell
    }
    
    // MARK: - UITableViewDataSource
    
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
            return cellCountForPushInfo(pushInfo)
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
            let cellCount = cellCountForPushInfo(pushInfo)
            if cellCount == 2 && indexPath.row == 1 {
                return resetCellForTableView(tableView, indexPath: indexPath, pushInfo: push)
            }
            if cellCount == 3 {
                // This implies either push and background fetch are disabled
                if indexPath.row == 1 {
                    if !push.pushPermitted {
                        return fixPushPermissionCellForTableView(tableView, indexPath: indexPath)
                    } else if !push.backgroundFetchPermitted {
                        return fixBackgroundFetchCellForTableView(tableView, indexPath: indexPath)
                    }
                } else if indexPath.row == 2 {
                    return resetCellForTableView(tableView, indexPath: indexPath, pushInfo: push)
                }
            }
            if cellCount == 4 {
                // This implies both push and background fetch are disabled
                if indexPath.row == 1 {
                    return fixPushPermissionCellForTableView(tableView, indexPath: indexPath)
                } else if indexPath.row == 2 {
                    return fixBackgroundFetchCellForTableView(tableView, indexPath: indexPath)
                } else if indexPath.row == 3 {
                    return resetCellForTableView(tableView, indexPath: indexPath, pushInfo: push)
                }
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
    
    // MARK: - OTRServerCapabilitiesDelegate
    
    @objc public func serverCapabilities(sender: OTRServerCapabilities, didDiscoverAllCapabilities allCapabilities: [XMPPJID : DDXMLElement]) {
        guard let caps = serverCapabilitiesModule else { return }
        capabilities = ServerCapabilityInfo.markAvailable(capabilities, serverCapabilitiesModule: caps)
        tableView.reloadData()
    }
    
    // MARK: - Cell Data
    
    private enum TableSection: UInt {
        case Push
        case Server
    }

}
