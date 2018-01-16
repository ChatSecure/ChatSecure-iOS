//
//  OTRSubscription.swift
//  ChatSecureCore
//
//  Created by N-Pex on 2018-01-11.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

/**
 The possible values for a subscription value
 https://xmpp.org/rfcs/rfc6121.html#roster-syntax-items-subscription
 We separate them into two enums, subscription and pending
 */

@objc public enum SubscriptionPendingAttribute: Int {
    case pendingNone
    case pendingIn
    case pendingOut
    case pendingOutIn
    
    public func isPendingIn() -> Bool {
        switch self {
        case .pendingIn, .pendingOutIn: return true
        default: return false
        }
    }
    
    public mutating func setPendingIn(pending:Bool) {
        if (pending) {
            switch self {
            case .pendingNone: self = .pendingIn
            case .pendingOut: self = .pendingOutIn
            default: break
            }
        } else {
            switch self {
            case .pendingIn: self = .pendingNone
            case .pendingOutIn: self = .pendingOut
            default: break
            }
        }
    }
    
    public func isPendingOut() -> Bool {
        switch self {
        case .pendingOut, .pendingOutIn: return true
        default: return false
        }
    }
    
    public mutating func setPendingOut(pending:Bool) {
        if (pending) {
            switch self {
            case .pendingNone: self = .pendingOut
            case .pendingIn: self = .pendingOutIn
            default: break
            }
        } else {
            switch self {
            case .pendingOut: self = .pendingNone
            case .pendingOutIn: self = .pendingIn
            default: break
            }
        }
    }
}

@objc public enum SubscriptionAttribute: Int, RawRepresentable {
    case none
    case to
    case from
    case both
    
    public typealias RawValue = String
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "from": self = .from
        case "to": self = .to
        case "both": self = .both
        default: self = .none
        }
    }
    
    public var rawValue: RawValue {
        switch self {
        case .from: return "from"
        case .to: return "to"
        case .both: return "both"
        default: return "none"
        }
    }
    
    public func isSubscribedTo() -> Bool {
        switch self {
        case .to, .both: return true
        default: return false
        }
    }
    
    public func isSubscribedFrom() -> Bool {
        switch self {
        case .from, .both: return true
        default: return false
        }
    }
}

// For Objective-C interop (can't use methods on an enum directly)
//
@objc public class SubscriptionPendingAttributeBridge: NSObject {
    @objc public static func isPendingOut(_ attribute:SubscriptionPendingAttribute) -> Bool {
        return attribute.isPendingOut()
    }
    
    @objc public static func setPendingOut(_ attribute:SubscriptionPendingAttribute, pending:Bool) -> SubscriptionPendingAttribute {
        var attr = attribute
        attr.setPendingOut(pending: pending)
        return attr
    }
    
    @objc public static func isPendingIn(_ attribute:SubscriptionPendingAttribute) -> Bool {
        return attribute.isPendingIn()
    }
    
    @objc public static func setPendingIn(_ attribute:SubscriptionPendingAttribute, pending:Bool) -> SubscriptionPendingAttribute {
        var attr = attribute
        attr.setPendingIn(pending: pending)
        return attr
    }
}

@objc public class SubscriptionAttributeBridge: NSObject {
    @objc public static func subscription(withString subscription:String) -> SubscriptionAttribute {
        return SubscriptionAttribute(rawValue: subscription) ?? .none
    }
    
    @objc public static func isSubscribedTo(_ attribute:SubscriptionAttribute) -> Bool {
        return attribute.isSubscribedTo()
    }

    @objc public static func isSubscribedFrom(_ attribute:SubscriptionAttribute) -> Bool {
        return attribute.isSubscribedFrom()
    }

}

