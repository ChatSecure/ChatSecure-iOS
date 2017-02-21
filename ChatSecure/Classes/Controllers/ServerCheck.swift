//
//  ServerCheck.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/15/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import OTRAssets

/**
 * The purpose of this class is to collect and process server
 * and push info in one place.
 *
 * All public members must be accessed from the main queue.
 */
@objc(OTRServerCheck)
public class ServerCheck: NSObject, OTRServerCapabilitiesDelegate {
    
    public let capsModule: OTRServerCapabilities
    public let push: PushController
    
    public var capabilities: [CapabilityCode : ServerCapabilityInfo]?
    public var pushInfo: PushInfo?
    
    public var pushInfoReady: ((_ pushInfo: PushInfo) -> ())?
    public var capabilitiesReady: ((_ capabilities: [CapabilityCode : ServerCapabilityInfo]) -> ())?
    
    deinit {
        capsModule.removeDelegate(self)
    }
    
    public init(capsModule: OTRServerCapabilities, push: PushController) {
        self.push = push
        self.capsModule = capsModule
        super.init()
        capsModule.addDelegate(self, delegateQueue: DispatchQueue.main)
        fetch()
    }
    
    /// set readyBlock to get result
    public func fetch() {
        refreshPush()
        refreshCapabilities()
    }
    
    /// Must be called from main queue
    public func refresh() {
        pushInfo = nil
        fetch()
    }
    
    private func checkReady() {
        if let ready = pushInfoReady, let push = pushInfo {
            ready(push)
        }
        if let ready = capabilitiesReady, let caps = capabilities {
            ready(caps)
        }
    }
    
    private func refreshPush() {
        push.gatherPushInfo(completion: { (info) in
            self.pushInfo = info
            self.checkReady()
            }, callbackQueue: DispatchQueue.main)
    }
    
    private func refreshCapabilities() {
        let caps = ServerCapabilityInfo.allCapabilities()
        capabilities = capsModule.markAvailable(capabilities: caps)
        checkReady()
    }
    
    // MARK: - OTRServerCapabilitiesDelegate
    
    @objc public func serverCapabilities(_ sender: OTRServerCapabilities, didDiscoverAllCapabilities allCapabilities: [XMPPJID : DDXMLElement]) {
        checkReady()
    }
}


