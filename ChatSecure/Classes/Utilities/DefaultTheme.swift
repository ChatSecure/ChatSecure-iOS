//
//  DefaultTheme.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 2/23/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation

/// Do not use this class directly, use OTRAppDelegate.theme
@objc public class DefaultTheme: NSObject, AppTheme {
    
    public let mainThemeColor = UIColor.white
    public let lightThemeColor = UIColor(white: 0.95, alpha: 1.0)
    public let buttonLabelColor = UIColor.darkGray
    
    public func setupAppearance() {
        
    }
    
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
    
    public func inviteViewController(for account: OTRAccount) -> UIViewController {
        return OTRInviteViewController(account: account)
    }
    
    public func keyManagementViewController(for account: OTRXMPPAccount, buddies: [OTRXMPPBuddy]) -> UIViewController {
        guard let connections = OTRDatabaseManager.shared.connections else {
            return UIViewController()
        }
        let form = KeyManagementViewController.profileFormDescriptorForAccount(account, buddies: buddies, connection: connections.read)
        let verify = KeyManagementViewController(accountKey: account.uniqueId, readConnection: connections.read, writeConnection: connections.write, form: form)
        return verify
    }
    
    public func accountDetailViewController(for account: OTRXMPPAccount, xmpp: XMPPManager) -> UIViewController {
        guard let connections = OTRDatabaseManager.shared.connections else {
            return UIViewController()
        }
        let detail = AccountDetailViewController(account: account, xmpp: xmpp, longLivedReadConnection: connections.longLivedRead, readConnection: connections.read, writeConnection: connections.write)
        return detail
    }
}
