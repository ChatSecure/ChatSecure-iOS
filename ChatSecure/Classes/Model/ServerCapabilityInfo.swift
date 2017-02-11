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
}

@objc(OTRCapabilityCode)
public enum CapabilityCode: UInt {
    case Unknown
    /// XEP-0198: Stream Management
    case XEP0198
    /// XEP-0357: Push
    case XEP0357
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
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return ServerCapabilityInfo(code: self.code, title: self.title, subtitle: self.subtitle, xmlns: self.xmlns, url: url)
    }
    
    public class func allCapabilities() -> [ServerCapabilityInfo] {
        var caps: [ServerCapabilityInfo] = []
        caps.append(ServerCapabilityInfo(
            code: .XEP0198,
            title: "Stream Management",
            subtitle: "XEP-0198: Provides better experience during temporary disconnections.",
            xmlns: "urn:xmpp:sm",
            url: NSURL(string: "https://xmpp.org/extensions/xep-0198.html")!))
        caps.append(ServerCapabilityInfo(
            code: .XEP0357,
            title: "Push",
            subtitle: "XEP-0357: Provides push messaging support.",
            xmlns: "urn:xmpp:push",
            url: NSURL(string: "https://xmpp.org/extensions/xep-0357.html")!))
        return caps
    }
    
    // MARK: Utility
    
    /**
     * This will determine which features are available.
     * Will do nothing if the module hasn't finished processing.
     */
    public class func markAvailable(capabilities: [ServerCapabilityInfo], serverCapabilitiesModule: OTRServerCapabilities) -> [ServerCapabilityInfo] {
        guard let allCaps = serverCapabilitiesModule.allCapabilities, let features = serverCapabilitiesModule.streamFeatures else {
            return capabilities
        }
        let allFeatures = OTRServerCapabilities.allFeaturesForCapabilities(allCaps, streamFeatures: features)
        var newCaps: [ServerCapabilityInfo] = []
        for var capInfo in capabilities {
            capInfo = capInfo.copy() as! ServerCapabilityInfo
            for feature in allFeatures {
                if feature.containsString(capInfo.xmlns) {
                    capInfo.status = .Available
                    break
                }
            }
            // if its not found, mark it unavailable
            if capInfo.status != .Available {
                capInfo.status = .Unavailable
            }
            newCaps.append(capInfo)
        }
        return newCaps
    }
}
