//
//  OTRXMPPRoom.swift
//  ChatSecure
//
//  Created by David Chiles on 10/7/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import UIKit
import YapDatabase.YapDatabaseRelationship

@objc open class OTRXMPPRoom: OTRYapDatabaseObject {
    
    @objc open var lastHistoryFetch: Date?
    
    @objc open var isArchived = false
    @objc open var muteExpiration:Date?
    @objc open var accountUniqueId:String?
    /** Your full JID for the room e.g. xmpp-development@conference.deusty.com/robbiehanson */
    @objc open var ownJID:String?
    
    /// JID of the room itself
    @objc open var jid:String?
    
    /// XMPPJID of the room itself
    public var roomJID: XMPPJID? {
        if let jid = jid {
            return XMPPJID(string: jid)
        } else {
            return nil
        }
    }
    
    @objc open var joined = false
    @objc open var messageText:String?
    @objc open var lastRoomMessageId:String?
    @objc open var subject:String?
    @objc open var roomPassword:String?
    override open var uniqueId:String {
        get {
            if let account = self.accountUniqueId {
                if let jid = self.jid {
                    return OTRXMPPRoom.createUniqueId(account, jid: jid)
                }
            }
            return super.uniqueId
        }
    }
    
    @objc open class func createUniqueId(_ accountId:String, jid:String) -> String {
        return accountId + jid
    }
    
    @objc open class func fetch(xmppRoom: XMPPRoom, transaction: YapDatabaseReadTransaction) -> OTRXMPPRoom? {
        guard let roomYapKey = xmppRoom.roomYapKey else {
            return nil
        }
        return OTRXMPPRoom.fetchObject(withUniqueID: roomYapKey, transaction: transaction)
    }
}

extension OTRXMPPRoom:OTRThreadOwner {
    /** New outgoing message. Unsaved! */
    public func outgoingMessage(withText text: String, transaction: YapDatabaseReadTransaction) -> OTRMessageProtocol {
        let message = OTRXMPPRoomMessage()!
        message.messageText = text
        message.messageDate = Date()
        message.roomJID = self.jid
        message.roomUniqueId = self.uniqueId
        message.senderJID = self.ownJID
        message.state = .needsSending
        message.originId = message.uniqueId
        return message
    }
    
    public var currentMessageText: String? {
        get {
            return self.messageText
        }
        set(currentMessageText) {
            self.messageText = currentMessageText
        }
    }
    
    public var lastMessageIdentifier: String? {
        get {
            return self.lastRoomMessageId
        }
        set(lastMessageIdentifier) {
            self.lastRoomMessageId = lastMessageIdentifier
        }
    }
    
    public func account(with transaction: YapDatabaseReadTransaction) -> OTRAccount? {
        return OTRAccount.fetchObject(withUniqueID: threadAccountIdentifier, transaction: transaction)
    }
    
    public var isMuted: Bool {
        guard let expiration = muteExpiration else {
            return false
        }
        if expiration > Date() {
            return true
        }
        return false
    }
    
    public var threadName: String {
        return self.subject ?? self.jid ?? ""
    }
    
    public var threadIdentifier: String {
        return self.uniqueId
    }
    
    public var threadCollection: String {
        return OTRXMPPRoom.collection
    }
    
    public var threadAccountIdentifier: String {
        return self.accountUniqueId ?? ""
    }
    
    public var avatarImage: UIImage {
        if let image = OTRImages.image(withIdentifier: self.uniqueId) {
            return image
        } else {
            // If not cached, generate a default image and store that.
            let seed = self.avatarSeed
            if let image = OTRGroupAvatarGenerator.avatarImage(withSeed: seed, width: 100, height: 100) {
                OTRImages.setImage(image, forIdentifier: self.uniqueId)
                return image
            } else {
                return OTRImages.avatarImage(withUniqueIdentifier: self.uniqueId, avatarData: nil, displayName: nil, username: self.threadName)
            }
        }
    }
    
    public var currentStatus: OTRThreadStatus {
        switch self.joined {
        case true:
            return .available
        default:
            return .offline
        }
    }
    
    public func lastMessage(with transaction: YapDatabaseReadTransaction) -> OTRMessageProtocol? {
        guard let viewTransaction = transaction.ext(OTRFilteredChatDatabaseViewExtensionName) as? YapDatabaseViewTransaction else {
            return nil
        }
        let message = viewTransaction.lastObject(inGroup: self.threadIdentifier) as? OTRMessageProtocol
        return message
    }
    
    public func numberOfUnreadMessages(with transaction: YapDatabaseReadTransaction) -> UInt {
        guard let indexTransaction = transaction.ext(SecondaryIndexName.messages) as? YapDatabaseSecondaryIndexTransaction else {
            return 0
        }
        let queryString = "Where \(MessageIndexColumnName.threadId) == ? AND \(MessageIndexColumnName.isMessageRead) == 0"
        let query = YapDatabaseQuery(string: queryString, parameters: [self.uniqueId])
        var count:UInt = 0
        let success = indexTransaction.getNumberOfRows(&count, matching: query)
        if (!success) {
            NSLog("Query error for OTRXMPPRoom numberOfUnreadMessagesWithTransaction")
        }
        return count
    }
    
    public var isGroupThread: Bool {
        return true
    }
}

extension OTRXMPPRoom {
    /// Generates seed value for OTRGroupAvatarGenerator
    var avatarSeed: String {
        var seed = self.uniqueId
        if let jidStr = self.jid,
            let jid = XMPPJID(string: jidStr),
            let user = jid.user {
            seed = user
        }
        return seed
    }
}


public extension OTRXMPPRoom {
    
    @objc public var bookmark: XMPPConferenceBookmark? {
        guard let jid = roomJID else { return nil }
        let bookmark = XMPPConferenceBookmark(jid: jid, bookmarkName: self.subject, nick: nil, autoJoin: true)
        return bookmark
    }
    
}

extension OTRXMPPRoom: YapDatabaseRelationshipNode {
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        guard let accountId = self.accountUniqueId else { return nil }
        let edgeName = YapDatabaseConstants.edgeName(.room)
        let edge = YapDatabaseRelationshipEdge(name: edgeName, destinationKey: accountId, collection: OTRXMPPAccount.collection, nodeDeleteRules: [YDB_NodeDeleteRules.deleteSourceIfDestinationDeleted])
        return [edge]
    }
}

public extension XMPPRoom {
    
    /// yapKey for OTRXMPPRoom
    public var roomYapKey: String? {
        guard let accountId = self.accountId else {
            return nil
        }
        return accountId + roomJID.bare
    }
}
