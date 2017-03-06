//
//  AccountDetailViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 3/5/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRAssets

struct DetailCellInfo {
    let title: String
    let action: (_ tableView: UITableView, _ indexPath: IndexPath) -> (Void)
}

enum TableSections: Int {
    case account
    case invite
    case details
    case loginlogout
    case delete
    static let allValues = [account, invite, details, loginlogout, delete]
}

enum AccountRows: Int {
    case account
    static let allValues = [account]
}

@objc(OTRAccountDetailViewController)
public class AccountDetailViewController: UITableViewController {
    
    var account: OTRXMPPAccount
    let longLivedReadConnection: YapDatabaseConnection
    let writeConnection: YapDatabaseConnection
    var detailCells: [DetailCellInfo] = []
    let DetailCellIdentifier = "DetailCellIdentifier"
    
    let xmpp: OTRXMPPManager
    public var serverCheck: ServerCheck
    
    public init(account: OTRXMPPAccount, xmpp: OTRXMPPManager, serverCheck: ServerCheck, longLivedReadConnection: YapDatabaseConnection, writeConnection: YapDatabaseConnection) {
        self.account = account
        self.longLivedReadConnection = longLivedReadConnection
        self.writeConnection = writeConnection
        self.xmpp = xmpp
        self.serverCheck = serverCheck
        super.init(style: .grouped)
    }
    
    public convenience init(account: OTRXMPPAccount, xmpp: OTRXMPPManager, push: PushController, longLivedReadConnection: YapDatabaseConnection, writeConnection: YapDatabaseConnection) {
        let serverCheck = ServerCheck(xmpp: xmpp, push: push)
        self.init(account: account, xmpp: xmpp, serverCheck: serverCheck, longLivedReadConnection: longLivedReadConnection, writeConnection: writeConnection)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = ACCOUNT_STRING()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))
        navigationItem.rightBarButtonItem = doneButton
        
        let bundle = OTRAssets.resourcesBundle()
        for identifier in [XMPPAccountCell.cellIdentifier(), SingleButtonTableViewCell.cellIdentifier()] {
            let nib = UINib(nibName: identifier, bundle: bundle)
            tableView.register(nib, forCellReuseIdentifier: identifier)
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: DetailCellIdentifier)
        
        detailCells = [
            DetailCellInfo(title: "Edit Account", action: { [weak self] (_, _) -> (Void) in
                guard let strongSelf = self else { return }
                strongSelf.showLoginView(account: strongSelf.account)
            }),
            DetailCellInfo(title: "Manage My Keys", action: { [weak self] (_, _) -> (Void) in
                guard let strongSelf = self else { return }
                strongSelf.showKeyManagement(account: strongSelf.account)
            }),
            DetailCellInfo(title: "Server Information", action: { [weak self] (_, _) -> (Void) in
                guard let strongSelf = self else { return }
                strongSelf.showServerInfo(account: strongSelf.account)
            })
        ]
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(loginStatusChanged(_:)), name: NSNotification.Name(rawValue: OTRXMPPLoginStatusNotificationName), object: nil)
        tableView.reloadData()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notifications
    
    @objc func loginStatusChanged(_ notification: Notification) {
        tableView.reloadData()
    }
    
    // MARK: - User Actions
    
    func showDeleteDialog(account: OTRXMPPAccount) {
        
    }
    
    func showLogoutDialog(account: OTRXMPPAccount) {
        
    }
    
    func inviteFriends(account: OTRXMPPAccount) {
        
    }
    
    func showLoginView(account: OTRXMPPAccount) {
        guard let login = OTRBaseLoginViewController(for: account) else { return }
        navigationController?.pushViewController(login, animated: true)
    }
    
    func showKeyManagement(account: OTRXMPPAccount) {
        let form = UserProfileViewController.profileFormDescriptorForAccount(account, buddies: [], connection: writeConnection)
        let keys = UserProfileViewController(accountKey: account.uniqueId, connection: writeConnection, form: form)
        navigationController?.pushViewController(keys, animated: true)
    }
    
    func showServerInfo(account: OTRXMPPAccount) {
        let scvc = ServerCapabilitiesViewController(serverCheck: serverCheck)
        navigationController?.pushViewController(scvc, animated: true)
    }
    
    @objc private func doneButtonPressed(_ sender: Any?) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source & delegate

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return TableSections.allValues.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableSection = TableSections(rawValue: section) else {
            return 0
        }
        switch tableSection {
        case .account:
            return AccountRows.allValues.count
        case .details:
            return detailCells.count
        case .delete, .loginlogout, .invite:
            return 1
        }
    }

    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = TableSections(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        switch section {
        case .account:
            if let row = AccountRows(rawValue: indexPath.row) {
                switch row {
                case .account:
                    return accountCell(account: account, tableView: tableView, indexPath: indexPath)
                }
            }
        case .details:
            return detailCell(account: account, tableView: tableView, indexPath: indexPath)
        case .invite:
            return inviteCell(account: account, tableView: tableView, indexPath: indexPath)
        case .delete:
            return deleteCell(account: account, tableView: tableView, indexPath: indexPath)
        case .loginlogout:
            return loginLogoutCell(account: account, tableView: tableView, indexPath: indexPath)
        }
        return UITableViewCell() // this should never be reached
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = TableSections(rawValue: indexPath.section) else {
            return
        }
        switch section {
        case .account:
            if let row = AccountRows(rawValue: indexPath.row) {
                switch row {
                case .account:
                    break
                }
            }
        case .details:
            let detail = detailCells[indexPath.row]
            detail.action(tableView, indexPath)
            return
        case .invite:
            break
        case .delete:
            break
        case .loginlogout:
            break
        }
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = super.tableView(tableView, heightForRowAt: indexPath)
        guard let section = TableSections(rawValue: indexPath.section) else {
            return height
        }
        switch section {
        case .account:
            if let row = AccountRows(rawValue: indexPath.row) {
                switch row {
                case .account:
                    height = XMPPAccountCell.cellHeight()
                    break
                }
            }
        case .details, .invite, .delete, .loginlogout:
            break
        }
        return height
    }
    
    // MARK: - Cells
    
    func accountCell(account: OTRXMPPAccount, tableView: UITableView, indexPath: IndexPath) -> XMPPAccountCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: XMPPAccountCell.cellIdentifier(), for: indexPath) as? XMPPAccountCell else {
            return XMPPAccountCell()
        }
        cell.setAppearance(account: account)
        cell.infoButton.isHidden = true
        cell.selectionStyle = .none
        return cell
    }
    
    func loginLogoutCell(account: OTRXMPPAccount, tableView: UITableView, indexPath: IndexPath) -> SingleButtonTableViewCell {
        let cell = singleButtonCell(account: account, tableView: tableView, indexPath: indexPath)
        
        switch xmpp.connectionStatus {
        case .disconnected, .connecting:
            cell.button.setTitle("Login", for: .normal)
            cell.buttonAction = { [weak self] (cell, sender) in
                guard let strongSelf = self else { return }
                strongSelf.showLoginView(account: strongSelf.account)
            }
            break
        case .connected:
            cell.button.setTitle("Logout", for: .normal)
            cell.buttonAction = { [weak self] (cell, sender) in
                guard let strongSelf = self else { return }
                strongSelf.showLogoutDialog(account: strongSelf.account)
            }
            cell.button.setTitleColor(UIColor.red, for: .normal)
            break
        }
        return cell
    }
    
    func detailCell(account: OTRXMPPAccount, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let detail = detailCells[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: DetailCellIdentifier, for: indexPath)
        cell.textLabel?.text = detail.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func singleButtonCell(account: OTRXMPPAccount, tableView: UITableView, indexPath: IndexPath) -> SingleButtonTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SingleButtonTableViewCell.cellIdentifier(), for: indexPath) as? SingleButtonTableViewCell else {
            return SingleButtonTableViewCell()
        }
        cell.button.setTitleColor(nil, for: .normal)
        cell.selectionStyle = .none
        return cell
    }
    
    func inviteCell(account: OTRXMPPAccount, tableView: UITableView, indexPath: IndexPath) -> SingleButtonTableViewCell {
        let cell = singleButtonCell(account: account, tableView: tableView, indexPath: indexPath)
        cell.button.setTitle("Invite Friends", for: .normal)
        cell.buttonAction = { [weak self] (cell, sender) in
            guard let strongSelf = self else { return }
            strongSelf.inviteFriends(account: strongSelf.account)
        }
        return cell
    }
    
    func deleteCell(account: OTRXMPPAccount, tableView: UITableView, indexPath: IndexPath) -> SingleButtonTableViewCell {
        let cell = singleButtonCell(account: account, tableView: tableView, indexPath: indexPath)
        cell.button.setTitle("Delete Account", for: .normal)
        cell.buttonAction = { [weak self] (cell, sender) in
            guard let strongSelf = self else { return }
            strongSelf.showDeleteDialog(account: strongSelf.account)
        }
        cell.button.setTitleColor(UIColor.red, for: .normal)
        return cell
    }

}
