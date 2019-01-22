//
//  OTRProtocolManager.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 1/22/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation
import OTRAssets

@objc
public class OTRProtocolManager: NSObject {
    private var protocols: [String:OTRProtocol] = [:]
    private var xmppManagers: [XMPPManager] {
        return protocols.values.compactMap { $0 as? XMPPManager }
    }
    
    @objc
    public func existsProtocolForAccount(_ account: OTRAccount) -> Bool {
        return existsProtocol(for: account)
    }

    public func existsProtocol(for account: OTRAccount) -> Bool {
        return protocols[account.uniqueId] != nil
    }
    
    @objc
    public func protocolForAccount(_ account: OTRAccount) -> OTRProtocol? {
        return protocols[account.uniqueId]
    }
    
    public func `protocol`(for account: OTRAccount) -> OTRProtocol? {
        return protocolForAccount(account)
    }
    
    @objc
    public func xmppManagerForAccount(_ account: OTRAccount) -> XMPPManager? {
        return xmppManager(for: account)
    }
    
    public func xmppManager(for account: OTRAccount) -> XMPPManager? {
        return protocolForAccount(account) as? XMPPManager
    }
    
    @objc
    public func removeProtocolForAccount(_ account: OTRAccount) {
        removeProtocolForAccount(account)
    }
    
    public func removeProtocol(for account: OTRAccount) {
        protocols[account.uniqueId] = nil
    }

    @objc
    public func isAccountConnected(_ account: OTRAccount) -> Bool {
        return xmppManager(for: account)?.loginStatus == .authenticated
    }
    
    @objc
    public func loginAccount(_ account: OTRAccount) {
        loginAccount(account, userInitiated: false)
    }
    
    @objc
    public func loginAccount(_ account: OTRAccount, userInitiated: Bool) {
        xmppManager(for: account)?.connectUserInitiated(userInitiated)
    }
    
    @objc
    public func loginAccounts(_ accounts: [OTRAccount]) {
        accounts.forEach {
            self.loginAccount($0)
        }
    }
    
    @objc
    public func goAwayForAllAccounts() {
        xmppManagers.forEach {
            $0.goAway()
        }
    }
    
    @objc
    public func sendMessage(_ message: OTROutgoingMessage) {
        send(message)
    }
    
    /// This should probably be moved elsewhere
    public func send(_ message: OTROutgoingMessage) {
        let _account = OTRDatabaseManager.shared.connections?.read.fetch {
            message.buddy(with: $0)?.account(with: $0)
        }
        guard let account = _account else { return }
        xmppManager(for: account)?.send(message)
    }
    
    @objc
    public func disconnectAllAccounts() {
        disconnectAllAccountsSocketOnly(false, timeout: 0, completionBlock: nil)
    }
    
    @objc
    public func disconnectAllAccountsSocketOnly(_ socketOnly: Bool,
                                                timeout: TimeInterval,
                                                completionBlock: (()->Void)?) {
        let group = DispatchGroup()
        var observers: [NSKeyValueObservation] = []
        xmppManagers.forEach { (xmpp) in
            guard xmpp.loginStatus != .disconnected else {
                return
            }
            group.enter()
            let observer = xmpp.observe(\.loginStatus, changeHandler: { (xmpp, change) in
                if xmpp.loginStatus == .disconnected {
                    group.leave()
                }
            })
            observers.append(observer)
            xmpp.disconnectSocketOnly(socketOnly)
        }
        group.notify(queue: .main) {
            observers.removeAll()
            completionBlock?()
        }
    }
}

public extension OTRProtocolManager {
    #if DEBUG
    /// when OTRBranding.pushStagingAPIURL is nil (during tests) a valid value must be supplied for the integration tests to pass
    private static let pushApiEndpoint: URL = OTRBranding.pushStagingAPIURL ?? URL(string: "http://localhost")!
    #else
    private static let pushApiEndpoint: URL = OTRBranding.pushAPIURL
    #endif
    
    @objc public static let encryptionManager = OTREncryptionManager()
    @objc public static let shared = OTRProtocolManager()
    @objc public static func sharedInstance() -> OTRProtocolManager {
        return OTRProtocolManager.shared
    }
    
    @objc public static let pushController = PushController(baseURL: OTRProtocolManager.pushApiEndpoint, sessionConfiguration: URLSessionConfiguration.ephemeral)
}
