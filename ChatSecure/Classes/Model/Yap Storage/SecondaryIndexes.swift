//
//  SecondaryIndexes.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 11/7/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

/// YapDatabase extension names for Secondary Indexes
@objc public class SecondaryIndexName: NSObject {
    @objc public static let messages = "OTRMessagesSecondaryIndex"
    @objc public static let signal = "OTRYapDatabseMessageIdSecondaryIndexExtension"
    @objc public static let roomOccupants = "SecondaryIndexName.roomOccupantIndex"
}

@objc public class MessageSecondaryIndexName: NSObject {
    /// XEP-0359 origin-id
    @objc public static let originId = "SecondaryIndexNameOriginId"
    /// XEP-0359 stanza-id
    @objc public static let stanzaId = "SecondaryIndexNameStanzaId"
}

@objc public class RoomOccupantSecondaryIndexName: NSObject {
    /// jid
    @objc public static let jid = "OTRYapDatabaseRoomOccupantJidSecondaryIndexColumnName"
}

extension YapDatabaseSecondaryIndexOptions {
    convenience init(whitelist: [String]) {
        let set = Set(whitelist)
        let whitelist = YapWhitelistBlacklist(whitelist: set)
        self.init()
        self.allowedCollections = whitelist
    }
}

public extension YapDatabaseSecondaryIndex {
    @objc public static var messageIndex: YapDatabaseSecondaryIndex {
        let columns: [String:YapDatabaseSecondaryIndexType] = [
            OTRYapDatabaseMessageIdSecondaryIndexColumnName: .text,
            OTRYapDatabaseRemoteMessageIdSecondaryIndexColumnName: .text,
            OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName: .text,
            OTRYapDatabaseUnreadMessageSecondaryIndexColumnName: .integer,
            MessageSecondaryIndexName.originId: .text,
            MessageSecondaryIndexName.stanzaId: .text
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
                dict[OTRYapDatabaseRemoteMessageIdSecondaryIndexColumnName] = remoteMessageId
            }
            if message.messageKey.count > 0 {
                dict[OTRYapDatabaseMessageIdSecondaryIndexColumnName] = message.messageKey
            }
            dict[OTRYapDatabaseUnreadMessageSecondaryIndexColumnName] = message.isMessageRead
            if message.threadId.count > 0 {
                dict[OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName] = message.threadId
            }
            if let originId = message.originId, originId.count > 0 {
                dict[MessageSecondaryIndexName.originId] = originId
            }
            if let stanzaId = message.stanzaId, stanzaId.count > 0 {
                dict[MessageSecondaryIndexName.stanzaId] = stanzaId
            }
        }
        // These are actually the same collection
        let options = YapDatabaseSecondaryIndexOptions(whitelist: [OTRBaseMessage.collection, OTRXMPPRoomMessage.collection])
        let secondaryIndex = YapDatabaseSecondaryIndex(setup: setup, handler: handler, versionTag: "5", options: options)
        return secondaryIndex
    }
    
    @objc public static var signalIndex: YapDatabaseSecondaryIndex {
        let columns: [String:YapDatabaseSecondaryIndexType] = [
            OTRYapDatabaseSignalSessionSecondaryIndexColumnName: .text,
            OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName: .integer,
            OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName: .text
        ]
        let setup = YapDatabaseSecondaryIndexSetup(capacity: UInt(columns.count))
        columns.forEach { (key, value) in
            setup.addColumn(key, with: value)
        }
        
        let handler = YapDatabaseSecondaryIndexHandler.withObjectBlock { (transaction, dict, collection, key, object) in
            if let session = object as? OTRSignalSession {
                if session.name.count > 0 {
                    let value = "\(session.accountKey)-\(session.name)"
                    dict[OTRYapDatabaseSignalSessionSecondaryIndexColumnName] = value
                }
                return // no point in checking if object is other types
            }
            if let preKey = object as? OTRSignalPreKey {
                dict[OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName] = preKey.keyId
                if preKey.accountKey.count > 0 {
                    dict[OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName] = preKey.accountKey
                }
                return // no point in checking if object is other types
            }
        }
        let options = YapDatabaseSecondaryIndexOptions(whitelist: [OTRSignalPreKey.collection,OTRSignalSession.collection])
        let secondaryIndex = YapDatabaseSecondaryIndex(setup: setup, handler: handler, versionTag: "5", options: options)
        return secondaryIndex
    }
    
    @objc public static var roomOccupantIndex: YapDatabaseSecondaryIndex {
        let columns: [String:YapDatabaseSecondaryIndexType] = [
            RoomOccupantSecondaryIndexName.jid: .text
        ]
        let setup = YapDatabaseSecondaryIndexSetup(capacity: UInt(columns.count))
        columns.forEach { (key, value) in
            setup.addColumn(key, with: value)
        }
        
        let handler = YapDatabaseSecondaryIndexHandler.withObjectBlock { (transaction, dict, collection, key, object) in
            guard let occupant = object as? OTRXMPPRoomOccupant else {
                return
            }
            if let jid = occupant.jid, jid.count > 0 {
                dict[RoomOccupantSecondaryIndexName.jid] = jid
            }
        }
        let options = YapDatabaseSecondaryIndexOptions(whitelist: [OTRXMPPRoomOccupant.collection])
        let secondaryIndex = YapDatabaseSecondaryIndex(setup: setup, handler: handler, versionTag: "1", options: options)
        return secondaryIndex
    }

}
