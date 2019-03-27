//
//  SecondaryIndexes.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 11/7/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

extension YapDatabaseSecondaryIndexOptions {
    convenience init(whitelist: [String]) {
        let set = Set(whitelist)
        let whitelist = YapWhitelistBlacklist(whitelist: set)
        self.init()
        self.allowedCollections = whitelist
    }
}

extension YapDatabaseSecondaryIndex {
    @objc public static var buddyIndex: YapDatabaseSecondaryIndex {
        let columns: [String:YapDatabaseSecondaryIndexType] = [
            BuddyIndexColumnName.accountKey: .text,
            BuddyIndexColumnName.username: .text
        ]
        let setup = YapDatabaseSecondaryIndexSetup(capacity: UInt(columns.count))
        columns.forEach { (key, value) in
            setup.addColumn(key, with: value)
        }
        let handler = YapDatabaseSecondaryIndexHandler.withObjectBlock { (transaction, dict, collection, key, object) in
            guard let buddy = object as? OTRXMPPBuddy else {
                return
            }
            dict[BuddyIndexColumnName.accountKey] = buddy.accountUniqueId
            dict[BuddyIndexColumnName.username] = buddy.username
        }
        let options = YapDatabaseSecondaryIndexOptions(whitelist: [OTRXMPPBuddy.collection])
        let secondaryIndex = YapDatabaseSecondaryIndex(setup: setup, handler: handler, versionTag: "2", options: options)
        return secondaryIndex
    }
    
    
    @objc public static var messageIndex: YapDatabaseSecondaryIndex {
        let columns: [String:YapDatabaseSecondaryIndexType] = [
            MessageIndexColumnName.messageKey: .text,
            MessageIndexColumnName.remoteMessageId: .text,
            MessageIndexColumnName.threadId: .text,
            MessageIndexColumnName.isMessageRead: .integer,
            MessageIndexColumnName.originId: .text,
            MessageIndexColumnName.stanzaId: .text
        ]
        let setup = YapDatabaseSecondaryIndexSetup(capacity: UInt(columns.count))
        columns.forEach { (key, value) in
            setup.addColumn(key, with: value)
        }
        
        let handler = YapDatabaseSecondaryIndexHandler.withObjectBlock { (transaction, dict, collection, key, object) in
            guard let message = object as? OTRMessageProtocol else {
                return
            }
            if let remoteMessageId = message.remoteMessageId,
                remoteMessageId.count > 0 {
                dict[MessageIndexColumnName.remoteMessageId] = remoteMessageId
            }
            if message.messageKey.count > 0 {
                dict[MessageIndexColumnName.messageKey] = message.messageKey
            }
            dict[MessageIndexColumnName.isMessageRead] = message.isMessageRead
            if message.threadId.count > 0 {
                dict[MessageIndexColumnName.threadId] = message.threadId
            }
            if let originId = message.originId, originId.count > 0 {
                dict[MessageIndexColumnName.originId] = originId
            }
            if let stanzaId = message.stanzaId, stanzaId.count > 0 {
                dict[MessageIndexColumnName.stanzaId] = stanzaId
            }
        }
        // These are actually the same collection
        let options = YapDatabaseSecondaryIndexOptions(whitelist: [OTRBaseMessage.collection, OTRXMPPRoomMessage.collection])
        let secondaryIndex = YapDatabaseSecondaryIndex(setup: setup, handler: handler, versionTag: "6", options: options)
        return secondaryIndex
    }
    
    @objc public static var signalIndex: YapDatabaseSecondaryIndex {
        let columns: [String:YapDatabaseSecondaryIndexType] = [
            SignalIndexColumnName.session: .text,
            SignalIndexColumnName.preKeyId: .integer,
            SignalIndexColumnName.preKeyAccountKey: .text
        ]
        let setup = YapDatabaseSecondaryIndexSetup(capacity: UInt(columns.count))
        columns.forEach { (key, value) in
            setup.addColumn(key, with: value)
        }
        
        let handler = YapDatabaseSecondaryIndexHandler.withObjectBlock { (transaction, dict, collection, key, object) in
            if let session = object as? OTRSignalSession {
                if session.name.count > 0 {
                    dict[SignalIndexColumnName.session] = session.sessionKey
                }
            } else if let preKey = object as? OTRSignalPreKey {
                dict[SignalIndexColumnName.preKeyId] = preKey.keyId
                if preKey.accountKey.count > 0 {
                    dict[SignalIndexColumnName.preKeyAccountKey] = preKey.accountKey
                }
            }
        }
        let options = YapDatabaseSecondaryIndexOptions(whitelist: [OTRSignalPreKey.collection,OTRSignalSession.collection])
        let secondaryIndex = YapDatabaseSecondaryIndex(setup: setup, handler: handler, versionTag: "6", options: options)
        return secondaryIndex
    }
    
    @objc public static var roomOccupantIndex: YapDatabaseSecondaryIndex {
        let columns: [String:YapDatabaseSecondaryIndexType] = [
            RoomOccupantIndexColumnName.jid: .text,
            RoomOccupantIndexColumnName.realJID: .text,
            RoomOccupantIndexColumnName.roomUniqueId: .text,
            RoomOccupantIndexColumnName.buddyUniqueId: .text,
            ]
        let setup = YapDatabaseSecondaryIndexSetup(capacity: UInt(columns.count))
        columns.forEach { (key, value) in
            setup.addColumn(key, with: value)
        }
        
        let handler = YapDatabaseSecondaryIndexHandler.withObjectBlock { (transaction, dict, collection, key, object) in
            guard let occupant = object as? OTRXMPPRoomOccupant else {
                return
            }
            if let jid = occupant.jid {
                dict[RoomOccupantIndexColumnName.jid] = jid.full
            }
            if let realJID = occupant.realJID {
                dict[RoomOccupantIndexColumnName.realJID] = realJID.bare
            }
            if let roomUniqueId = occupant.roomUniqueId, roomUniqueId.count > 0 {
                dict[RoomOccupantIndexColumnName.roomUniqueId] = roomUniqueId
            }
            if let buddyUniqueId = occupant.buddyUniqueId, buddyUniqueId.count > 0 {
                dict[RoomOccupantIndexColumnName.buddyUniqueId] = buddyUniqueId
            }
        }
        let options = YapDatabaseSecondaryIndexOptions(whitelist: [OTRXMPPRoomOccupant.collection])
        let secondaryIndex = YapDatabaseSecondaryIndex(setup: setup, handler: handler, versionTag: "6", options: options)
        return secondaryIndex
    }
    
    @objc public static var mediaItemIndex: YapDatabaseSecondaryIndex {
        let columns: [String:YapDatabaseSecondaryIndexType] = [
            MediaItemIndexColumnName.mediaItemId: .text,
            MediaItemIndexColumnName.transferProgress: .real,
            MediaItemIndexColumnName.isIncoming: .integer
        ]
        let setup = YapDatabaseSecondaryIndexSetup(capacity: UInt(columns.count))
        columns.forEach { (key, value) in
            setup.addColumn(key, with: value)
        }
        let handler = YapDatabaseSecondaryIndexHandler.withObjectBlock { (transaction, dict, collection, key, object) in
            guard let mediaItem = object as? OTRMediaItem else {
                return
            }
            dict[MediaItemIndexColumnName.mediaItemId] = mediaItem.uniqueId
            dict[MediaItemIndexColumnName.transferProgress] = mediaItem.transferProgress
            dict[MediaItemIndexColumnName.isIncoming] = mediaItem.isIncoming
        }
        let options = YapDatabaseSecondaryIndexOptions(whitelist: [OTRMediaItem.collection])
        let secondaryIndex = YapDatabaseSecondaryIndex(setup: setup, handler: handler, versionTag: "1", options: options)
        return secondaryIndex
    }
}

// MARK: - Extensions

extension OTRSignalSession {
    /// "\(accountKey)-\(name)", only used for SecondaryIndex lookups
    public var sessionKey: String {
        return OTRSignalSession.sessionKey(accountKey: accountKey, name: name)
    }
    
    /// "\(accountKey)-\(name)", only used for SecondaryIndex lookups
    public static func sessionKey(accountKey: String, name: String) -> String {
        return "\(accountKey)-\(name)"
    }
}

extension OTRXMPPBuddy {
    /// This function should only be used when the secondary index is not ready
    private static func slowLookup(jid: XMPPJID,
                                   accountUniqueId: String,
                                   transaction: YapDatabaseReadTransaction) -> OTRXMPPBuddy? {
        DDLogWarn("WARN: Using slow O(n) lookup for OTRXMPPBuddy: \(jid)")
        var buddy: OTRXMPPBuddy? = nil
        transaction.enumerateKeysAndObjects(inCollection: OTRXMPPBuddy.collection) { (key, object, stop) in
            if let potentialMatch = object as? OTRXMPPBuddy,
                potentialMatch.username == jid.bare {
                buddy = potentialMatch
                stop.pointee = true
            }
        }
        return buddy
    }
    
    
    /// Fetch buddy matching JID using secondary index
    @objc public static func fetchBuddy(jid: XMPPJID,
                                        accountUniqueId: String,
                                        transaction: YapDatabaseReadTransaction) -> OTRXMPPBuddy? {
        guard let indexTransaction = transaction.ext(SecondaryIndexName.buddy) as? YapDatabaseSecondaryIndexTransaction else {
            DDLogError("Error looking up OTRXMPPBuddy via SecondaryIndex: Extension not ready.")
            return self.slowLookup(jid:jid, accountUniqueId:accountUniqueId, transaction: transaction)
        }
        let queryString = "Where \(BuddyIndexColumnName.accountKey) == ? AND \(BuddyIndexColumnName.username) == ?"
        let query = YapDatabaseQuery(string: queryString, parameters: [accountUniqueId, jid.bare])
        
        var matchingBuddies: [OTRXMPPBuddy] = []
        let success = indexTransaction.enumerateKeysAndObjects(matching: query) { (collection, key, object, stop) in
            if let matchingBuddy = object as? OTRXMPPBuddy {
                matchingBuddies.append(matchingBuddy)
            }
        }
        if !success {
            DDLogError("Error looking up OTRXMPPBuddy with query \(query) \(jid) \(accountUniqueId)")
            return nil
        }
        if matchingBuddies.count > 1 {
            DDLogWarn("WARN: More than one OTRXMPPBuddy matching query \(query) \(jid) \(accountUniqueId): \(matchingBuddies.count)")
        }
//        #if DEBUG
//            if matchingBuddies.count == 0 {
//                DDLogWarn("WARN: No OTRXMPPBuddy matching query \(jid) \(accountUniqueId)")
//                let buddy = slowLookup(jid: jid, accountUniqueId: accountUniqueId, transaction: transaction)
//                if buddy != nil {
//                    DDLogWarn("WARN: Found buddy using O(n) lookup that wasn't found in secondary index: \(jid) \(accountUniqueId)")
//                }
//            }
//        #endif
        return matchingBuddies.first
    }
}

// MARK: - Constants

/// YapDatabase extension names for Secondary Indexes
@objc public class SecondaryIndexName: NSObject {
    @objc public static let messages = "OTRMessagesSecondaryIndex"
    @objc public static let signal = "OTRYapDatabseMessageIdSecondaryIndexExtension"
    @objc public static let roomOccupants = "SecondaryIndexName_roomOccupantIndex"
    @objc public static let buddy = "SecondaryIndexName_buddy"
    @objc public static let mediaItems = "SecondaryIndexName_mediaItems"
}

@objc public class BuddyIndexColumnName: NSObject {
    @objc public static let accountKey = "BuddyIndexColumnName_accountKey"
    @objc public static let username = "BuddyIndexColumnName_username"
}

@objc public class MessageIndexColumnName: NSObject {
    @objc public static let messageKey = "OTRYapDatabaseMessageIdSecondaryIndexColumnName"
    @objc public static let remoteMessageId = "OTRYapDatabaseRemoteMessageIdSecondaryIndexColumnName"
    @objc public static let threadId = "OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName"
    @objc public static let isMessageRead = "OTRYapDatabaseUnreadMessageSecondaryIndexColumnName"
    
    
    /// XEP-0359 origin-id
    @objc public static let originId = "SecondaryIndexNameOriginId"
    /// XEP-0359 stanza-id
    @objc public static let stanzaId = "SecondaryIndexNameStanzaId"
}

@objc public class RoomOccupantIndexColumnName: NSObject {
    /// jids
    @objc public static let jid = "OTRYapDatabaseRoomOccupantJidSecondaryIndexColumnName"
    @objc public static let realJID = "RoomOccupantIndexColumnName_realJID"
    @objc public static let roomUniqueId = "RoomOccupantIndexColumnName_roomUniqueId"
    @objc public static let buddyUniqueId = "RoomOccupantIndexColumnName_buddyUniqueId"
}

@objc public class SignalIndexColumnName: NSObject {
    @objc public static let session = "OTRYapDatabaseSignalSessionSecondaryIndexColumnName"
    @objc public static let preKeyId = "OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName"
    @objc public static let preKeyAccountKey = "OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName"
}

@objc public class MediaItemIndexColumnName: NSObject {
    @objc public static let mediaItemId = "MediaItemIndexColumnName_mediaItemId"
    @objc public static let transferProgress = "MediaItemIndexColumnName_transferProgress"
    @objc public static let isIncoming = "MediaItemIndexColumnName_isIncoming"
}
