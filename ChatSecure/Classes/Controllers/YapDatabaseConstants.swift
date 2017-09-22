//
//  YapDatabaseConstants.swift
//  ChatSecure
//
//  Created by David Chiles on 4/15/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

public class DatabaseExtensionName: NSObject {
    public static let groupOccupantsViewName = "GroupOccupantsViewName"
    public static let buddyDeleteActionViewName = "BuddyDeleteActionViewName"
    public static let relationshipExtensionName = "OTRYapDatabaseRelationshipName"
    public static let actionManagerName = "OTRYapDatabaseActionManager"
    public static let secondaryIndexName = "OTRYapDatabseMessageIdSecondaryIndexExtension"
    public static let buddyFTSExtensionName = "OTRBuddyBuddyNameSearchDatabaseViewExtensionName"
    public static let buddySearchResultsViewName = "DatabaseExtensionName.BuddySearchResultsView"
    public static let messageQueueBrokerViewName = "DatabaseExtensionName.MessageQueueBrokerViewName"
}

public class RelationshipEdgeName: NSObject {
    public static let buddyAccountEdgeName = "account"
    public static let subscriptionRequestAccountEdgeName = "OTRXMPPPresenceSubscriptionRequestEdges.account"
    public static let messageBuddyEdgeName = "buddy"
    public static let messageMediaEdgeName = "media"
    public static let omemoDeviceEdgeName = "OmemoDeviceEdgeName"
    public static let signalSignedPreKey = "SignalSignedPreKey"
    public static let messageActionEdgeName = "MessageActionEdgeName"
    public static let buddyActionEdgeName = "BuddyActionEdgeName"
    /// for OTRDownloadMessage -> OTRBaseMessage
    public static let download = "download"
}

public class DatabaseNotificationName:NSObject {
    public static let longLivedTransactionChanges = "DatabaseNotificationName.LongLivedTransactionChanges"
}

public class DatabaseNotificationKey:NSObject {
    public static let extensionName = "DatabaseNotificationKey.ExtensionName"
    public static let connectionChanges = "DatabaseNotificationKey.ConnectionChanges"
}

public class BuddyFTSColumnName: NSObject {
    public static let username = "username"
    public static let displayName = "displayName"
}
