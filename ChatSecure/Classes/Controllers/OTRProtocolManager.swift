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
