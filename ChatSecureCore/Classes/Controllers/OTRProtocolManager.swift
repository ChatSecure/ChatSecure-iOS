//
//  OTRProtocolManager.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 1/22/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation
import OTRAssets

extension OTRProtocolManager {
    #if DEBUG
    /// when OTRBranding.pushStagingAPIURL is nil (during tests) a valid value must be supplied for the integration tests to pass
    private static let pushApiEndpoint: URL = OTRBranding.pushStagingAPIURL ?? URL(string: "http://localhost")!
    #else
    private static let pushApiEndpoint: URL = OTRBranding.pushAPIURL
    #endif
    
    @objc public static let encryptionManager = OTREncryptionManager()
    
    @objc public static let pushController = PushController(baseURL: OTRProtocolManager.pushApiEndpoint, sessionConfiguration: URLSessionConfiguration.ephemeral)
}

extension OTRProtocolManager {
    @objc(disconnectAllAccountsSocketOnly:timeout:completionBlock:)
    public func disconnectAllAccounts(socketOnly: Bool, timeout: TimeInterval, completion: (()->Void)? = nil) {
        let group = DispatchGroup()
        let tokens: [NSKeyValueObservation] = allProtocols
            .compactMap { $0 as? XMPPManager }
            .filter { $0.loginStatus != .disconnected }
            .map {
                group.enter()
                let token = $0.observe(\.loginStatus) { xmppManager, change in
                    if xmppManager.loginStatus == .disconnected {
                        group.leave()
                    }
                }
                $0.disconnectSocketOnly(socketOnly)
                return token
            }
        DispatchQueue.global(qos: .default).async {
            let result = group.wait(timeout: .now() + timeout)
            switch result {
            case .success:
                break
            case .timedOut:
                DDLogWarn("Exceeded max time for disconnect")
            }
            tokens.forEach { $0.invalidate() }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
}
