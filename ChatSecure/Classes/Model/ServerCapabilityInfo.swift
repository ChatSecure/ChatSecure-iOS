//
//  ServerCapabilityInfo.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/10/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit

@objc(OTRCapabilityStatus)
public enum CapabilityStatus: UInt {
    case Unknown
    case Available
    case Unavailable
    case Warning
}

public enum CapabilityCode: String {
    case Unknown = "Unknown"
    /// XEP-0198: Stream Management
    case XEP0198 = "XEP-0198"
    /// XEP-0357: Push
    case XEP0357 = "XEP-0357"
    /// XEP-0363: HTTP File Upload https://xmpp.org/extensions/xep-0363.html
    case XEP0363 = "XEP-0363"
    /// XEP-0352: Client State Indication https://xmpp.org/extensions/xep-0352.html
    case XEP0352 = "XEP-0352"
    /// XEP-0359: Unique and Stable Stanza IDs https://xmpp.org/extensions/xep-0359.html
    case XEP0359 = "XEP-0359"
    /// XEP-0313: Message Archive Management https://xmpp.org/extensions/xep-0313.html
    case XEP0313 = "XEP-0313"
}

@objc(OTRServerCapabilityInfo)
public class ServerCapabilityInfo: NSObject, NSCopying {
    public var status: CapabilityStatus = .Unknown
    public let code: CapabilityCode
    public let title: String
    public let subtitle: String
    /// used to match against caps xml
    public let xmlns: String
    public let url: NSURL
    
    public init(code: CapabilityCode, title: String, subtitle: String, xmlns: String, url: NSURL) {
        self.code = code
        self.title = title
        self.subtitle = subtitle
        self.xmlns = xmlns
        self.url = url
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return ServerCapabilityInfo(code: self.code, title: self.title, subtitle: self.subtitle, xmlns: self.xmlns, url: url)
    }
    
    
    public class func allCapabilities() -> [CapabilityCode: ServerCapabilityInfo] {
        var caps: [CapabilityCode: ServerCapabilityInfo] = [:]
        caps[.XEP0198] = ServerCapabilityInfo(
            code: .XEP0198,
            title: "Stream Management",
            subtitle: "\(CapabilityCode.XEP0198.rawValue): Provides better experience during temporary disconnections.",
            xmlns: "urn:xmpp:sm",
            url: NSURL(string: "https://xmpp.org/extensions/xep-0198.html")!)
        caps[.XEP0357] = ServerCapabilityInfo(
            code: .XEP0357,
            title: "Push",
            subtitle: "\(CapabilityCode.XEP0357.rawValue): Provides push messaging support.",
            xmlns: "urn:xmpp:push",
            url: NSURL(string: "https://xmpp.org/extensions/xep-0357.html")!)
        caps[.XEP0363] = ServerCapabilityInfo(
            code: .XEP0363,
            title: "HTTP File Upload",
            subtitle: "\(CapabilityCode.XEP0363.rawValue): Provides file transfer for media messaging.",
            xmlns: XMPPHTTPFileUploadNamespace,
            url: NSURL(string: "https://xmpp.org/extensions/xep-0363.html")!)
        caps[.XEP0352] = ServerCapabilityInfo(
            code: .XEP0352,
            title: "Client State Indication",
            subtitle: "\(CapabilityCode.XEP0352.rawValue): Helps reduce network usage when running in the background.",
            xmlns: "urn:xmpp:csi",
            url: NSURL(string: "https://xmpp.org/extensions/xep-0352.html")!)
        caps[.XEP0359] = ServerCapabilityInfo(
            code: .XEP0359,
            title: "Unique and Stable Stanza IDs",
            subtitle: "\(CapabilityCode.XEP0359.rawValue): Improves message deduplication accuracy.",
            xmlns: "urn:xmpp:sid",
            url: NSURL(string: "https://xmpp.org/extensions/xep-0359.html")!)
        caps[.XEP0313] = ServerCapabilityInfo(
            code: .XEP0313,
            title: "Message Archive Management",
            subtitle: "\(CapabilityCode.XEP0313.rawValue): History synchronization across your devices.",
            xmlns: "urn:xmpp:mam",
            url: NSURL(string: "https://xmpp.org/extensions/xep-0313.html")!)
        return caps
    }
    
    
    
}

extension OTRServerCapabilities {
    // MARK: Utility

    /**
     * This will determine which features are available.
     * Will return nil if the module hasn't finished processing.
     */
    public func markAvailable(capabilities: [CapabilityCode : ServerCapabilityInfo]) -> [CapabilityCode :ServerCapabilityInfo]? {
        guard let allCaps = self.allCapabilities, let features = self.streamFeatures else {
            return nil
        }
        let allFeatures = OTRServerCapabilities.allFeatures(forCapabilities: allCaps, streamFeatures: features)
        var newCaps: [CapabilityCode : ServerCapabilityInfo] = [:]
        for (_, var capInfo) in capabilities {
            capInfo = capInfo.copy() as! ServerCapabilityInfo
            for feature in allFeatures {
                if feature.contains(capInfo.xmlns) {
                    capInfo.status = .Available
                    break
                }
            }
            // if its not found, mark it unavailable
            if capInfo.status != .Available {
                capInfo.status = .Unavailable
            }
            newCaps[capInfo.code] = capInfo
        }
        return newCaps
    }
}
