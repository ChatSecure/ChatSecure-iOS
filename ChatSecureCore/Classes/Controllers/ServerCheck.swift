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
public class ServerCheck: XMPPModule {
    
    @objc public let push: PushController
    @objc public let serverCapabilities: OTRServerCapabilities
    @objc public let xmppCapabilities: XMPPCapabilities
    @objc public let pushModule: XMPPPushModule
    
    @objc public var result = ServerCheckResult()
    
    @objc public static let UpdateNotificationName = Notification.Name(rawValue: "ServerCheckUpdateNotification")

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// pushModule should be activated elsewhere
    @objc public init(push: PushController,
                      pushModule: XMPPPushModule,
                      dispatchQueue: DispatchQueue? = nil) {
        self.push = push
        let capsStorage = XMPPCapabilitiesCoreDataStorage(inMemoryStore: ())!
        let capabilities = XMPPCapabilities(capabilitiesStorage: capsStorage, dispatchQueue: dispatchQueue)
        self.xmppCapabilities = capabilities
        self.serverCapabilities = OTRServerCapabilities(capabilities: capabilities, dispatchQueue: dispatchQueue)

        self.pushModule = pushModule
        super.init(dispatchQueue: dispatchQueue)
        
        self.xmppCapabilities.autoFetchHashedCapabilities = true
        self.xmppCapabilities.autoFetchNonHashedCapabilities = true
        self.xmppCapabilities.autoFetchMyServerCapabilities = true
        
        serverCapabilities.addDelegate(self, delegateQueue: moduleQueue)
        pushModule.addDelegate(self, delegateQueue: moduleQueue)
        NotificationCenter.default.addObserver(self, selector: #selector(pushAccountChanged(_:)), name: Notification.Name(rawValue: OTRPushAccountDeviceChanged), object: push)
        NotificationCenter.default.addObserver(self, selector: #selector(pushAccountChanged(_:)), name: Notification.Name(rawValue: OTRPushAccountTokensChanged), object: push)
        fetch()
    }
    
    // MARK: XMPPModule overrides
    
    @discardableResult override public func activate(_ xmppStream: XMPPStream) -> Bool {
        guard super.activate(xmppStream),
            xmppCapabilities.activate(xmppStream),
            serverCapabilities.activate(xmppStream)
            else {
                return false
        }
        return true
    }
    
    public override func deactivate() {
        serverCapabilities.deactivate()
        xmppCapabilities.deactivate()
        super.deactivate()
    }
    
    // MARK: Public API
    
    @objc public func getCombinedPushStatus() -> ServerCheckPushStatus {
        if let xmpp = xmppStream, xmpp.state != .STATE_XMPP_CONNECTED || !xmpp.isAuthenticated {
            return .unknown
        }
        return result.getCombinedPushStatus()
    }
    
    
    
    /// set pushInfoReady, capabilitiesReady, pushStatusUpdate to get result
    @objc public func fetch() {
        refreshPush()
        refreshCapabilities()
        checkReady()
    }
    
    /// Must be called from main queue
    @objc public func refresh() {
        result.pushInfo = nil
        serverCapabilities.fetchAllCapabilities()
        fetch()
    }
    
    // This will refresh the pushStatusUpdate block
    private func updatePushStatus() {
        guard let push = result.pushInfo, let pubsubEndpoint = push.pubsubEndpoint else { return }
        if let jid = XMPPJID(user: nil, domain: pubsubEndpoint, resource: nil) {
            let status = pushModule.registrationStatus(forServerJID: jid)
            result.pushStatus = status
            postUpdateNotification()
        }
    }
    
    @objc private func pushAccountChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.refresh()
        }
    }
    
    private func checkReady() {
        if let _ = result.pushInfo {
            postUpdateNotification()
        }
        if let _ = result.capabilities {
            postUpdateNotification()
        }
        updatePushStatus()
    }
    
    private func postUpdateNotification() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: type(of: self).UpdateNotificationName, object: self)
        }
    }
    
    private func refreshPush() {
        push.gatherPushInfo(completion: { (info) in
            self.result.pushInfo = info
            self.checkReady()
            }, callbackQueue: DispatchQueue.main)
    }
    
    private func refreshCapabilities() {
        let caps = ServerCapabilityInfo.allCapabilities()
        result.capabilities = serverCapabilities.markAvailable(capabilities: caps)
        checkReady()
    }
    
}

// MARK: - OTRServerCapabilitiesDelegate

extension ServerCheck: OTRServerCapabilitiesDelegate {
    
    @objc public func serverCapabilities(_ sender: OTRServerCapabilities, didDiscoverCapabilities capabilities: [XMPPJID : XMLElement]) {
        refreshCapabilities()
    }
    
}

// MARK: - XMPPPushDelegate

extension ServerCheck: XMPPPushDelegate {
    
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
    
    public func pushModule(_ module: XMPPPushModule, readyWithCapabilities caps: XMLElement, jid: XMPPJID) {
        // This _should_ be handled elsewhere in OTRServerCapabilities
        // Not sure why it's not working properly
        if let caps = result.capabilities {
            caps[.XEP0357]?.status = .Available
        }
        checkReady()
    }
}

@objc
public enum ServerCheckPushStatus: UInt {
    case unknown
    case broken
    case working
}

@objc(OTRServerCheckResult)
public class ServerCheckResult: NSObject {
    public var capabilities: [CapabilityCode : ServerCapabilityInfo]?
    public var pushInfo: PushInfo?
    public var pushStatus: XMPPPushStatus?
    
    /** This lets you collect all push info in one place */
    fileprivate func getCombinedPushStatus() -> ServerCheckPushStatus {
        var checkStatus: ServerCheckPushStatus = .unknown
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
}

