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
public class ServerCheck: NSObject, OTRServerCapabilitiesDelegate, XMPPPushDelegate {
    
    public let capsModule: OTRServerCapabilities
    public let push: PushController
    public let xmppPush: XMPPPushModule
    
    public var capabilities: [CapabilityCode : ServerCapabilityInfo]?
    public var pushInfo: PushInfo?
    
    public var pushInfoReady: ((_ pushInfo: PushInfo) -> ())?
    public var capabilitiesReady: ((_ capabilities: [CapabilityCode : ServerCapabilityInfo]) -> ())?
    public var pushStatusUpdate: ((_ pushStatus: XMPPPushStatus) -> ())?
    
    deinit {
        capsModule.removeDelegate(self)
        xmppPush.removeDelegate(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    public init(capsModule: OTRServerCapabilities, push: PushController, xmppPush: XMPPPushModule) {
        self.push = push
        self.capsModule = capsModule
        self.xmppPush = xmppPush
        super.init()
        capsModule.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppPush.addDelegate(self, delegateQueue: DispatchQueue.main)
        NotificationCenter.default.addObserver(self, selector: #selector(pushAccountChanged(_:)), name: Notification.Name(rawValue: OTRPushAccountDeviceChanged), object: push)
        NotificationCenter.default.addObserver(self, selector: #selector(pushAccountChanged(_:)), name: Notification.Name(rawValue: OTRPushAccountTokensChanged), object: push)
        fetch()
    }
    
    /// set pushInfoReady, capabilitiesReady, pushStatusUpdate to get result
    public func fetch() {
        refreshPush()
        refreshCapabilities()
        updatePushStatus()
    }
    
    /// Must be called from main queue
    public func refresh() {
        pushInfo = nil
        fetch()
    }
    
    // This will refresh the pushStatusUpdate block
    private func updatePushStatus() {
        guard let push = pushInfo else { return }
        if let jid = XMPPJID(user: nil, domain: push.pubsubEndpoint, resource: nil),
            let update = pushStatusUpdate {
            let status = xmppPush.registrationStatus(forServerJID: jid)
            update(status)
        }
    }
    
    @objc private func pushAccountChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.refresh()
        }
    }
    
    private func checkReady() {
        if let push = pushInfo {
            if let ready = pushInfoReady {
                ready(push)
            }
        }
        if let ready = capabilitiesReady, let caps = capabilities {
            ready(caps)
        }
        updatePushStatus()
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
    
    @objc public func serverCapabilities(_ sender: OTRServerCapabilities, didDiscoverAllCapabilities allCapabilities: [XMPPJID : XMLElement]) {
        checkReady()
    }
    
    // MARK: - XMPPPushDelegate
    
    public func pushModule(_ module: XMPPPushModule, didRegisterWithResponseIq responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        updatePushStatus()
    }
    
    public func pushModule(_ module: XMPPPushModule, failedToRegisterWithErrorIq errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        updatePushStatus()
    }
    
    public func pushModule(_ module: XMPPPushModule, disabledPushForServerJID serverJID: XMPPJID, node: String?, responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        updatePushStatus()
    }
    
    public func pushModule(_ module: XMPPPushModule, failedToDisablePushWithErrorIq errorIq: XMPPIQ?, serverJID: XMPPJID, node: String?, outgoingIq: XMPPIQ) {
        updatePushStatus()
    }
    
    public func pushModuleReady(_ module: XMPPPushModule) {
        updatePushStatus()
    }
    
}


