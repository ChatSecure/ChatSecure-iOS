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
    public var pushStatus: XMPPPushStatus?
    
    /** ServerCheckStatus combines all other variables */
    public var checkStatusUpdate: ((_ checkStatus: ServerCheckStatus) -> ())?
    
    public var pushInfoReady: ((_ pushInfo: PushInfo) -> ())?
    public var capabilitiesReady: ((_ capabilities: [CapabilityCode : ServerCapabilityInfo]) -> ())?
    public var pushStatusUpdate: ((_ pushStatus: XMPPPushStatus) -> ())?
    
    deinit {
        capsModule.removeDelegate(self)
        xmppPush.removeDelegate(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    public convenience init(xmppManager: OTRXMPPManager, push: PushController) {
        self.init(capsModule: xmppManager.serverCapabilities, push: push, xmppPush: xmppManager.xmppPushModule)
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
    
    /** This lets you collect all push info in one place */
    public func getStatus() -> ServerCheckStatus {
        var checkStatus: ServerCheckStatus = .unknown
        if let pushInfo = pushInfo, !pushInfo.pushMaybeWorks() {
            return .broken
        }
        if let pushStatus = pushStatus, pushStatus != .registered {
            return .broken
        }
        if let pushCap = capabilities?[.XEP0357], pushCap.status != .Available {
            return .broken
        }
        guard let caps = capabilities, let push = pushInfo, let status = pushStatus else {
            return .unknown
        }
        var xepExists = false
        if let pushCap = caps[.XEP0357], pushCap.status == .Available {
            xepExists = true
        }
        let pushAcctWorks = push.pushMaybeWorks()
        let xmppWorks = status == .registered
        if xepExists && pushAcctWorks && xmppWorks {
            checkStatus = .working
        } else {
            checkStatus = .broken
        }
        return checkStatus
    }
    
    /// set pushInfoReady, capabilitiesReady, pushStatusUpdate to get result
    public func fetch() {
        refreshPush()
        refreshCapabilities()
        checkReady()
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
            self.pushStatus = status
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
        updateServerCheckStatus()
    }
    
    private func updateServerCheckStatus() {
        if let statusUpdate = checkStatusUpdate {
            let status = getStatus()
            statusUpdate(status)
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
    
    @objc public func serverCapabilities(_ sender: OTRServerCapabilities, didDiscoverAllCapabilities allCapabilities: [XMPPJID : XMLElement]) {
        checkReady()
    }
    
    // MARK: - XMPPPushDelegate
    
    public func pushModule(_ module: XMPPPushModule, didRegisterWithResponseIq responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        checkReady()
    }
    
    public func pushModule(_ module: XMPPPushModule, failedToRegisterWithErrorIq errorIq: XMPPIQ?, outgoingIq: XMPPIQ) {
        checkReady()
    }
    
    public func pushModule(_ module: XMPPPushModule, disabledPushForServerJID serverJID: XMPPJID, node: String?, responseIq: XMPPIQ, outgoingIq: XMPPIQ) {
        checkReady()
    }
    
    public func pushModule(_ module: XMPPPushModule, failedToDisablePushWithErrorIq errorIq: XMPPIQ?, serverJID: XMPPJID, node: String?, outgoingIq: XMPPIQ) {
        checkReady()
    }
    
    public func pushModuleReady(_ module: XMPPPushModule) {
        checkReady()
    }
}

@objc
public enum ServerCheckStatus: UInt {
    case unknown
    case broken
    case working
}

