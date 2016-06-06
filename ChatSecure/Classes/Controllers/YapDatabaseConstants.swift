//
//  YapDatabaseConstants.swift
//  ChatSecure
//
//  Created by David Chiles on 4/15/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

@objc public enum DatabaseExtensionName: Int {
    case UnsentGroupMessagesViewName
    case GroupOccupantsViewName
    case BuddyDeleteActionViewName
    case RelationshipExtensionName
    case ActionManagerName
    case SecondaryIndexName
    case BuddyFTSExtensionName
    case BuddySearchResultsViewName
    case MessageQueueBrokerViewName
    
    public func name() -> String {
        switch self {
            case UnsentGroupMessagesViewName: return "UnsentGroupMessagesViewName"
            case GroupOccupantsViewName: return "GroupOccupantsViewName"
            case BuddyDeleteActionViewName: return "BuddyDeleteActionViewName"
            case RelationshipExtensionName: return "OTRYapDatabaseRelationshipName"
            case ActionManagerName: return "OTRYapDatabaseActionManager"
            case SecondaryIndexName: return "OTRYapDatabseMessageIdSecondaryIndexExtension"
            case BuddyFTSExtensionName: return "OTRBuddyBuddyNameSearchDatabaseViewExtensionName"
            case BuddySearchResultsViewName: return "DatabaseExtensionName.BuddySearchResultsView"
            case MessageQueueBrokerViewName: return "DatabaseExtensionName.MessageQueueBrokerViewName"
        }
    }
}

@objc public enum RelationshipEdgeName: Int {
    case BuddyAccountEdgeName
    case SubscriptionRequestAccountEdgeName
    case MessageBuddyEdgeName
    case MessageMediaEdgeName
    
    public func name() -> String {
        switch self {
            case BuddyAccountEdgeName: return "account"
            case SubscriptionRequestAccountEdgeName: return "OTRXMPPPresenceSubscriptionRequestEdges.account"
            case MessageBuddyEdgeName: return "buddy"
            case .MessageMediaEdgeName: return "media"
        }
    }
}

@objc public enum DatbaseNotificationName:Int {
    case RegisteredExtension
    
    public func name() -> String {
        switch self {
        case RegisteredExtension: return "DatbaseNotificationName.RegisteredExtension"
        }
    }
}

@objc public enum DatabaseNotificationKey:Int {
    case ExtensionName
    
    public func name() -> String {
        switch self {
        case ExtensionName: return "DatabaseNotificationKey.ExtensionName"
        }
    }
}

@objc public enum BuddyFTSColumnName:Int {
    case Username
    case DisplayName
    
    public func name() -> String {
        switch self {
        case Username: return "username"
        case DisplayName: return "displayName"
        }
    }
}

/// This is for briding to obj-c. Looking for a better way of using swift enums and stirngs.
@objc public class YapDatabaseConstants: NSObject {

    public class func edgeName(edgeName:RelationshipEdgeName) -> String {
        return edgeName.name()
    }
    
    public class func extensionName(extensionName:DatabaseExtensionName) -> String {
        return extensionName.name()
    }
    
    public class func notificationName(notificationName:DatbaseNotificationName) -> String {
        return notificationName.name()
    }
    
    public class func notificationKeyName(notificationKeyName:DatabaseNotificationKey) -> String {
        return notificationKeyName.name()
    }
    
    public class func buddyFTSColumnName(columnName:BuddyFTSColumnName) -> String {
        return columnName.name()
    }
    
}