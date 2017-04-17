//
//  YapDatabaseConstants.swift
//  ChatSecure
//
//  Created by David Chiles on 4/15/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

@objc public enum DatabaseExtensionName: Int {
    case unsentGroupMessagesViewName
    case groupOccupantsViewName
    case buddyDeleteActionViewName
    case relationshipExtensionName
    case actionManagerName
    case secondaryIndexName
    case buddyFTSExtensionName
    case buddySearchResultsViewName
    case messageQueueBrokerViewName
    
    public func name() -> String {
        switch self {
            case .unsentGroupMessagesViewName: return "UnsentGroupMessagesViewName"
            case .groupOccupantsViewName: return "GroupOccupantsViewName"
            case .buddyDeleteActionViewName: return "BuddyDeleteActionViewName"
            case .relationshipExtensionName: return "OTRYapDatabaseRelationshipName"
            case .actionManagerName: return "OTRYapDatabaseActionManager"
            case .secondaryIndexName: return "OTRYapDatabseMessageIdSecondaryIndexExtension"
            case .buddyFTSExtensionName: return "OTRBuddyBuddyNameSearchDatabaseViewExtensionName"
            case .buddySearchResultsViewName: return "DatabaseExtensionName.BuddySearchResultsView"
            case .messageQueueBrokerViewName: return "DatabaseExtensionName.MessageQueueBrokerViewName"
        }
    }
}

@objc public enum RelationshipEdgeName: Int {
    case buddyAccountEdgeName
    case subscriptionRequestAccountEdgeName
    case messageBuddyEdgeName
    case messageMediaEdgeName
    case omemoDeviceEdgeName
    case signalSignedPreKey
    case messageActionEdgeName
    case buddyActionEdgeName
    
    public func name() -> String {
        switch self {
            case .buddyAccountEdgeName: return "account"
            case .subscriptionRequestAccountEdgeName: return "OTRXMPPPresenceSubscriptionRequestEdges.account"
            case .messageBuddyEdgeName: return "buddy"
            case .messageMediaEdgeName: return "media"
            case .omemoDeviceEdgeName: return "OmemoDeviceEdgeName"
            case .signalSignedPreKey: return "SignalSignedPreKey"
            case .messageActionEdgeName: return "MessageActionEdgeName"
            case .buddyActionEdgeName: return "BuddyActionEdgeName"
        }
    }
}

public class DatabaseNotificationName:NSObject {
    public static let LongLivedTransactionChanges = "DatabaseNotificationName.LongLivedTransactionChanges"
}

open class DatabaseNotificationKey:NSObject {
    open static let ExtensionName = "DatabaseNotificationKey.ExtensionName"
    open static let ConnectionChanges = "DatabaseNotificationKey.ConnectionChanges"
}

@objc public enum BuddyFTSColumnName:Int {
    case username
    case displayName
    
    public func name() -> String {
        switch self {
        case .username: return "username"
        case .displayName: return "displayName"
        }
    }
}

/// This is for briding to obj-c. Looking for a better way of using swift enums and stirngs.
@objc open class YapDatabaseConstants: NSObject {

    open class func edgeName(_ edgeName:RelationshipEdgeName) -> String {
        return edgeName.name()
    }
    
    open class func extensionName(_ extensionName:DatabaseExtensionName) -> String {
        return extensionName.name()
    }
    
    open class func buddyFTSColumnName(_ columnName:BuddyFTSColumnName) -> String {
        return columnName.name()
    }
    
}
