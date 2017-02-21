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

public class ServerCapabilitiesViewController: UITableViewController {

    private let check: ServerCheck
    private var capabilities: [ServerCapabilityInfo] = []
    private let tableSections: [TableSection] = [.Push, .Server]
    
    /// This will take ownership of serverCheck and overwrite whatever is in serverCheck.readyBlock
    public init (serverCheck: ServerCheck) {
        self.check = serverCheck
        self.check.fetch()
        super.init(style: .grouped)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Data Loading and Refreshing
    
    /// Will refresh all data for the view
    @objc private func refreshAllData(sender: AnyObject?) {
        check.refresh()
    }
    
    // MARK: - User Interaction
    
    @objc private func doneButtonPressed(sender: AnyObject?) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let bundle = OTRAssets.resourcesBundle()
        for identifier in [ServerCapabilityTableViewCell.cellIdentifier(), PushAccountTableViewCell.cellIdentifier(), SingleButtonTableViewCell.cellIdentifier(), TwoButtonTableViewCell.cellIdentifier()] {
            let nib = UINib(nibName: identifier, bundle: bundle)
            tableView.register(nib, forCellReuseIdentifier: identifier)
        }

        tableView.allowsSelection = false
        
        self.title = Server_String()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(sender:)))
        navigationItem.rightBarButtonItem = doneButton

        // Add capabilities listener
        
        self.check.pushInfoReady = { [weak self] (pushInfo) in
            self?.tableView.reloadData()
        }
        self.check.capabilitiesReady = { [weak self] (caps) in
            self?.capabilities = Array(caps.values)
            self?.tableView.reloadData()
        }
    }

    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // This will allow us to refresh the permission prompts after use changes them in background
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAllData), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        refreshAllData(sender: nil)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
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
    private func resetCellForTableView(tableView: UITableView, indexPath: IndexPath, pushInfo: PushInfo) -> UITableViewCell {
        // Configure the account reset/deactivate cell
        guard let resetCell = tableView.dequeueReusableCell(withIdentifier: TwoButtonTableViewCell.cellIdentifier(), for: indexPath) as? TwoButtonTableViewCell else {
            return UITableViewCell()
        }
        resetCell.leftButton.setTitle(RESET_STRING(), for: .normal)
        resetCell.leftButton.setTitleColor(UIColor.red, for: .normal)
        resetCell.leftAction = { [weak self] (cell, sender) in
            self?.showDestructivePrompt(title: nil, buttonTitle: RESET_STRING(), handler: { (action) in
                self?.check.push.reset(completion: {
                    self?.check.refresh()
                    }, callbackQueue: DispatchQueue.main)
            })
        }
        resetCell.rightButton.setTitle(DEACTIVATE_STRING(), for: .normal)
        resetCell.rightButton.setTitleColor(UIColor.red, for: .normal)
        resetCell.rightButton.setTitleColor(UIColor.lightGray, for: .disabled)
        resetCell.rightAction = { [weak self] (cell, sender) in
            self?.showDestructivePrompt(title: nil, buttonTitle:  DEACTIVATE_STRING(), handler: { (action) in
                self?.check.push.deactivate(completion: {
                    self?.check.refresh()
                    }, callbackQueue: DispatchQueue.main)
            })
        }
        resetCell.rightButton.isEnabled = pushInfo.hasPushAccount
        return resetCell
    }
    
    /// Cell with button to prompt user to fix push permissions
    private func fixPushPermissionCellForTableView(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let permissionCell = tableView.dequeueReusableCell(withIdentifier: SingleButtonTableViewCell.cellIdentifier(), for: indexPath) as? SingleButtonTableViewCell else {
            return UITableViewCell()
        }
        permissionCell.button.setTitle(FIX_PERMISSIONS_STRING(), for: .normal)
        permissionCell.buttonAction = {  (cell, sender) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(appSettings)
            }
        }
        return permissionCell
    }
    
    /// Cell with button to prompt user to fix background fetch
    private func fixBackgroundFetchCellForTableView(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let fetchCell = tableView.dequeueReusableCell(withIdentifier: SingleButtonTableViewCell.cellIdentifier(), for: indexPath) as? SingleButtonTableViewCell else {
            return UITableViewCell()
        }
        fetchCell.button.setTitle(FIX_BACKGROUND_FETCH_STRING(), for: .normal)
        fetchCell.buttonAction = { (cell, sender) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(appSettings)
            }
        }
        return fetchCell
    }
    
    // MARK: - UITableViewDataSource
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableSections[section] {
        case .Push:
            return CHATSECURE_PUSH_STRING()
        case .Server:
            return Server_String()
        }
    }
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return tableSections.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableSections[section] {
        case .Push:
            return cellCountForPushInfo(pushInfo: check.pushInfo)
        case .Server:
            return capabilities.count
        }
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableSections[indexPath.section] {
        case .Push:
            let emptyCell = UITableViewCell()
            // Configure the main push account info cell
            if indexPath.row == 0 {
                guard let pushCell = tableView.dequeueReusableCell(withIdentifier: PushAccountTableViewCell.cellIdentifier(), for: indexPath) as? PushAccountTableViewCell,
                    let caps = check.capabilities else {
                        return emptyCell
                }
                pushCell.setPushInfo(pushInfo: check.pushInfo, pushCapabilities: caps[.XEP0357])
                pushCell.infoButtonBlock = { [weak self] (cell, sender) in
                    (self?.check.pushInfo?.pushAPIURL as NSURL?)?.promptToShow(from: self, sender: sender)
                }
                return pushCell
            }
            guard let push = check.pushInfo else {
                return emptyCell
            }
            let cellCount = cellCountForPushInfo(pushInfo: check.pushInfo)
            if cellCount == 2 && indexPath.row == 1 {
                return resetCellForTableView(tableView: tableView, indexPath: indexPath, pushInfo: push)
            }
            if cellCount == 3 {
                // This implies either push and background fetch are disabled
                if indexPath.row == 1 {
                    if !push.pushPermitted {
                        return fixPushPermissionCellForTableView(tableView: tableView, indexPath: indexPath)
                    } else if !push.backgroundFetchPermitted {
                        return fixBackgroundFetchCellForTableView(tableView: tableView, indexPath: indexPath)
                    }
                } else if indexPath.row == 2 {
                    return resetCellForTableView(tableView: tableView, indexPath: indexPath, pushInfo: push)
                }
            }
            if cellCount == 4 {
                // This implies both push and background fetch are disabled
                if indexPath.row == 1 {
                    return fixPushPermissionCellForTableView(tableView: tableView, indexPath: indexPath)
                } else if indexPath.row == 2 {
                    return fixBackgroundFetchCellForTableView(tableView: tableView, indexPath: indexPath)
                } else if indexPath.row == 3 {
                    return resetCellForTableView(tableView: tableView, indexPath: indexPath, pushInfo: push)
                }
            }
            return emptyCell // hopefully never get here
        case .Server:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ServerCapabilityTableViewCell.cellIdentifier(), for: indexPath) as? ServerCapabilityTableViewCell else {
                return UITableViewCell()
            }
            var cellInfo = capabilities[indexPath.row]
            if let pushInfo = check.pushInfo {
                // If push account isnt working, show a warning here
                if cellInfo.code == .XEP0357 && !pushInfo.pushMaybeWorks() && cellInfo.status == .Available {
                    cellInfo = cellInfo.copy() as! ServerCapabilityInfo
                    cellInfo.status = .Warning
                }
            }
            cell.setCapability(capability: cellInfo)
            cell.infoButtonBlock = { [weak self] (cell, sender) in
                if let strongSelf = self {
                    cellInfo.url.promptToShow(from: strongSelf, sender: sender)
                }
            }
            return cell
        }
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
    
    // MARK: - Cell Data
    
    private enum TableSection: UInt {
        case Push
        case Server
    }

}
