//
//  ServerCheck.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/15/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit

/**
 * The purpose of this class is to collect and process server
 * and push info in one place.
 *
 * All public members must be accessed from the main queue.
 */
@objc(OTRServerCheck)
public class ServerCheck: NSObject, OTRServerCapabilitiesDelegate {
    
    private let capsModule: OTRServerCapabilities
    private let push: PushController
    
    public var capabilities: [CapabilityCode : ServerCapabilityInfo]?
    public var pushInfo: PushInfo?
    
    public var pushInfoReady: ((pushInfo: PushInfo) -> ())?
    public var capabilitiesReady: ((capabilities: [CapabilityCode : ServerCapabilityInfo]) -> ())?
    
    deinit {
        capsModule.removeDelegate(self)
    }
    
    public init(capsModule: OTRServerCapabilities, push: PushController) {
        self.push = push
        self.capsModule = capsModule
        super.init()
        capsModule.addDelegate(self, delegateQueue: dispatch_get_main_queue())
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
            ready(pushInfo: push)
        }
        if let ready = capabilitiesReady, let caps = capabilities {
            ready(capabilities: caps)
        }
    }
    
    private func refreshPush() {
        push.gatherPushInfo({ (info) in
            self.pushInfo = info
            self.checkReady()
            }, callbackQueue: dispatch_get_main_queue())
    }
    
    private func refreshCapabilities() {
        let caps = ServerCapabilityInfo.allCapabilities()
        capabilities = capsModule.markAvailable(caps)
        checkReady()
    }
    
    // MARK: - OTRServerCapabilitiesDelegate
    
    @objc public func serverCapabilities(sender: OTRServerCapabilities, didDiscoverAllCapabilities allCapabilities: [XMPPJID : DDXMLElement]) {
        checkReady()
    }
}
