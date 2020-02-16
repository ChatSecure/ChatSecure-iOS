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

@objc(OTRServerCapabilitiesViewController)
public class ServerCapabilitiesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView: UITableView
    private let check: ServerCheck
    private var capabilities: [ServerCapabilityInfo] = []
    private let tableSections: [TableSection] = [.Push, .Server]
    private var xmppPushStatus: XMPPPushStatus = .unknown
    
    @objc public init (serverCheck: ServerCheck) {
        self.check = serverCheck
        self.check.fetch()
        self.tableView = UITableView(frame: CGRect.zero, style: .grouped)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Data Loading and Refreshing
    
    /// Will refresh all data for the view
    @objc private func refreshAllData(_ sender: Any?) {
        tableView.reloadData()
        check.refresh()
    }
    
    /// This will delete ALL your XEP-0357 push registration for this pubsub node
    private func unregisterForXMPPPush(_ sender: Any?) {
        guard let push = check.result.pushInfo,
            let pubsubEndpoint = push.pubsubEndpoint,
            let jid = XMPPJID(user: nil, domain: pubsubEndpoint, resource: nil) else {
            return
        }
        check.pushModule.disablePush(forServerJID: jid, node: nil, elementId: nil)
    }
    
    @objc func didRegisterUserNotificationSettings(_ notification: Notification) {
        tableView.reloadData()
    }
    
    @objc func serverCheckUpdate(_ notification: Notification) {
        if let caps = check.result.capabilities {
            capabilities = Array(caps.values)
        }
        if let status = check.result.pushStatus {
            xmppPushStatus = status
        }
        tableView.reloadData()
    }
    
    // MARK: - User Interaction
    
    @objc private func doneButtonPressed(_ sender: Any?) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        self.title = Server_String()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))
        navigationItem.rightBarButtonItem = doneButton
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoPinEdgesToSuperviewEdges()
        let bundle = OTRAssets.resourcesBundle
        for identifier in [ServerCapabilityTableViewCell.cellIdentifier(), PushAccountTableViewCell.cellIdentifier(), SingleButtonTableViewCell.cellIdentifier(), TwoButtonTableViewCell.cellIdentifier()] {
            let nib = UINib(nibName: identifier, bundle: bundle)
            tableView.register(nib, forCellReuseIdentifier: identifier)
        }
        tableView.allowsSelection = false
    }

    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // This will allow us to refresh the permission prompts after use changes them in background
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAllData), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EnablePushViewController.didRegisterUserNotificationSettings(_:)), name: NSNotification.Name(rawValue: OTRUserNotificationsChanged), object: nil)
        // Add capabilities listener
        NotificationCenter.default.addObserver(self, selector: #selector(serverCheckUpdate(_:)), name: ServerCheck.UpdateNotificationName, object: check)
        refreshAllData(nil)
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
            self?.showDestructivePrompt(title: nil, buttonTitle: RESET_STRING(), sender: sender, handler: { (action) in
                self?.unregisterForXMPPPush(sender)
                self?.check.push.reset(completion: {
                    self?.check.refresh()
                    self?.check.pushModule.refresh()
                    }, callbackQueue: DispatchQueue.main)
            })
        }
        resetCell.rightButton.setTitle(DEACTIVATE_STRING(), for: .normal)
        resetCell.rightButton.setTitleColor(UIColor.red, for: .normal)
        resetCell.rightButton.setTitleColor(UIColor.lightGray, for: .disabled)
        resetCell.rightAction = { [weak self] (cell, sender) in
            self?.showDestructivePrompt(title: nil, buttonTitle:  DEACTIVATE_STRING(), sender: sender, handler: { (action) in
                self?.unregisterForXMPPPush(sender)
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
            PushController.setPushPreference(.enabled)
            PushController.openAppSettings()
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
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings)
            }
        }
        return fetchCell
    }
    
    // MARK: - UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableSections[section] {
        case .Push:
            return CHATSECURE_PUSH_STRING()
        case .Server:
            return Server_String()
        }
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return tableSections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableSections[section] {
        case .Push:
            return cellCountForPushInfo(pushInfo: check.result.pushInfo)
        case .Server:
            return capabilities.count
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableSections[indexPath.section] {
        case .Push:
            let emptyCell = UITableViewCell()
            // Configure the main push account info cell
            if indexPath.row == 0 {
                guard let pushCell = tableView.dequeueReusableCell(withIdentifier: PushAccountTableViewCell.cellIdentifier(), for: indexPath) as? PushAccountTableViewCell else {
                        return emptyCell
                }
                pushCell.setPushInfo(pushInfo: check.result.pushInfo, pushCapabilities: check.result.capabilities?[.XEP0357], pushStatus: xmppPushStatus)
                pushCell.infoButtonBlock = { [weak self] (cell, sender) in
                    guard let strongSelf = self else {
                        return
                    }
                    (strongSelf.check.result.pushInfo?.pushAPIURL as NSURL?)?.promptToShow(from: strongSelf, sender: sender)
                }
                return pushCell
            }
            guard let push = check.result.pushInfo else {
                return emptyCell
            }
            let cellCount = cellCountForPushInfo(pushInfo: check.result.pushInfo)
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
            if let pushInfo = check.result.pushInfo {
                // If push account isnt working, show a warning here
                if cellInfo.code == .XEP0357 && cellInfo.status == .Available {
                    if !pushInfo.pushMaybeWorks() || xmppPushStatus != .registered {
                        cellInfo = cellInfo.copy() as! ServerCapabilityInfo
                        cellInfo.status = .Warning
                    }
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
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
