//
//  YapDatabaseConstants.swift
//  ChatSecure
//
//  Created by David Chiles on 4/15/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation


@objc public enum DatabaseExtensionName: Int {
    case groupOccupantsViewName
    case buddyDeleteActionViewName
    case relationshipExtensionName
    case actionManagerName
    case buddyFTSExtensionName
    case buddySearchResultsViewName
    case messageQueueBrokerViewName
    
    public func name() -> String {
        switch self {
            case .groupOccupantsViewName: return "GroupOccupantsViewName"
            case .buddyDeleteActionViewName: return "BuddyDeleteActionViewName"
            case .relationshipExtensionName: return "OTRYapDatabaseRelationshipName"
            case .actionManagerName: return "OTRYapDatabaseActionManager"
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
    case download // for OTRDownloadMessage -> OTRBaseMessage
    case room
    
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
            case .download: return "download"
            case .room: return "room"
        }
    }
}

@objc public class DatabaseNotificationName:NSObject {
    @objc public static let LongLivedTransactionChanges = "DatabaseNotificationName.LongLivedTransactionChanges"
}

@objc open class DatabaseNotificationKey:NSObject {
    @objc public static let ExtensionName = "DatabaseNotificationKey.ExtensionName"
    @objc public static let ConnectionChanges = "DatabaseNotificationKey.ConnectionChanges"
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

    @objc open class func edgeName(_ edgeName:RelationshipEdgeName) -> String {
        return edgeName.name()
    }
    
    @objc open class func extensionName(_ extensionName:DatabaseExtensionName) -> String {
        return extensionName.name()
    }
    
    @objc open class func buddyFTSColumnName(_ columnName:BuddyFTSColumnName) -> String {
        return columnName.name()
    }
    
}
