//
//  DefaultTheme.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 2/23/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation

@objc public class GlobalTheme: NSObject {
    @objc public static var shared: AppTheme = DefaultTheme()
}

@objc public class DefaultTheme: NSObject, AppTheme {
    
    public let mainThemeColor = UIColor.white
    public let lightThemeColor = UIColor(white: 0.95, alpha: 1.0)
    public let buttonLabelColor = UIColor.darkGray
    
    private var connections: DatabaseConnections? {
        return OTRDatabaseManager.shared.connections
    }
    
    public func setupAppearance() { }
    
    public func conversationViewController() -> UIViewController {
        return OTRConversationViewController()
    }
    
    public func messagesViewController() -> UIViewController {
        return OTRMessagesHoldTalkViewController()
    }
    
    public func settingsViewController() -> UIViewController {
        return OTRSettingsViewController()
    }
    
    public func composeViewController() -> UIViewController {
        return OTRComposeViewController()
    }
    
    public func inviteViewController(account: OTRAccount) -> UIViewController {
        return OTRInviteViewController(account: account)
    }
    
    public func accountDetailViewController(account: OTRXMPPAccount) -> UIViewController {
        guard let connections = self.connections,
            let xmpp = OTRProtocolManager.shared.xmppManager(for: account) else {
            return UIViewController()
        }
        
        let detail = AccountDetailViewController(account: account, xmpp: xmpp, longLivedReadConnection: connections.longLivedRead, readConnection: connections.ui, writeConnection: connections.write)
        return detail
    }
    
    public func keyManagementViewController(account: OTRXMPPAccount) -> UIViewController {
        guard let connections = self.connections else {
            return UIViewController()
        }
        let form = KeyManagementViewController.profileFormDescriptorForAccount(account, buddies: [], connection: connections.ui)
        let verify = KeyManagementViewController(accountKey: account.uniqueId, connections: connections, form: form)
        return verify
    }
    
    public func keyManagementViewController(buddy: OTRXMPPBuddy) -> UIViewController {
        guard let connections = self.connections else {
            return UIViewController()
        }
        let account = connections.ui.fetch {
            buddy.account(with: $0) as? OTRXMPPAccount
        }
        let form = KeyManagementViewController.profileFormDescriptorForAccount(account, buddies: [buddy], connection: connections.ui)
        let verify = KeyManagementViewController(accountKey: buddy.accountUniqueId, connections: connections, form: form)
        return verify
    }
    
    public func groupKeyManagementViewController(buddies: [OTRXMPPBuddy]) -> UIViewController {
        guard let connections = self.connections,
            let accountId = buddies.first?.accountUniqueId else {
            return UIViewController()
        }
        let form = KeyManagementViewController.profileFormDescriptorForAccount(nil, buddies: buddies, connection: connections.ui)
        let verify = KeyManagementViewController(accountKey: accountId, connections: connections, form: form)
        return verify
    }
    
    public func newUntrustedKeyViewController(buddies: [OTRXMPPBuddy]) -> UIViewController {
        guard let connections = self.connections,
            let accountId = buddies.first?.accountUniqueId else {
            return UIViewController()
        }
        let form = KeyManagementViewController.profileFormDescriptorForAccount(nil, buddies: buddies, connection: connections.ui)
        let verify = KeyManagementViewController(accountKey: accountId, connections: connections, form: form)
        return verify
    }
}
