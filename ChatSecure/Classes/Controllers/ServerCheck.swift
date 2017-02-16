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
    
    public typealias ReadyBlock = (pushInfo: PushInfo, capabilities: [CapabilityCode : ServerCapabilityInfo]) -> ()

    private let capsModule: OTRServerCapabilities
    private let push: PushController
    
    public var capabilities: [CapabilityCode : ServerCapabilityInfo]?
    public var pushInfo: PushInfo?
    
    public var readyBlock: ReadyBlock?
    
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
        guard let caps = capabilities, let push = pushInfo, let ready = readyBlock else {
            return
        }
        ready(pushInfo: push, capabilities: caps)
        readyBlock = nil
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
