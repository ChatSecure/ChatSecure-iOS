//
//  OTRXMPPBuddy.swift
//  ChatSecureCore
//
//  Created by N-Pex on 2018-01-18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

extension OTRXMPPBuddy {
    @objc public var subscribedTo: Bool {
        get {
            return self.subscription.isSubscribedTo()
        }
    }

    @objc public var subscribedFrom: Bool {
        get {
            return self.subscription.isSubscribedFrom()
        }
    }
    
    @objc public var pendingApproval: Bool {
        get {
            return self.pending.isPendingOut()
        }
        set(pending) {
            self.pending.setPendingOut(pending: pending)
        }
    }

    @objc public var askingForApproval: Bool {
        get {
            return self.pending.isPendingIn()
        }
        set(asking) {
            self.pending.setPendingIn(pending: asking)
        }
    }
}

extension SubscriptionPendingAttribute {
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

extension SubscriptionAttribute {
    
    public init(stringValue: String) {
        switch stringValue {
        case "from": self = .from
        case "to": self = .to
        case "both": self = .both
        default: self = .none
        }
    }
    
    public var stringValue: String {
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
        return SubscriptionAttribute(stringValue: subscription)
    }
}
