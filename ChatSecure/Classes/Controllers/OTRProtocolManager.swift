//
//  OTRProtocolManager.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 1/22/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation
import OTRAssets

public extension OTRProtocolManager {
    #if DEBUG
    private static let pushApiEndpoint: URL = OTRBranding.pushStagingAPIURL ?? OTRBranding.pushAPIURL
    #else
    private static let pushApiEndpoint: URL = OTRBranding.pushAPIURL
    #endif
    
    @objc public static let encryptionManager = OTREncryptionManager()
    
    @objc public static let pushController = PushController(baseURL: OTRProtocolManager.pushApiEndpoint, sessionConfiguration: URLSessionConfiguration.ephemeral)
}
