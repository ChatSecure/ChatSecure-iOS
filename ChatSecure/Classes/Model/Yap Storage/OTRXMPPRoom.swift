//
//  OTRXMPPRoom.swift
//  ChatSecure
//
//  Created by David Chiles on 10/7/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import UIKit
import YapDatabase.YapDatabaseRelationship

@objc public enum RoomSecurity: Int {
    /// will choose omemo if _any_ occupants have available keys
    case best = 0
    case plaintext = 1
    case omemo = 2
}

@objc public enum RoomUserState: Int {
    case invited = 0
    case hasViewed = 1
}

@objc open class OTRXMPPRoom: OTRYapDatabaseObject {
    
    @objc open var lastHistoryFetch: Date?
    
    @objc open var isArchived = false
    @objc open var muteExpiration:Date?
    @objc open var accountUniqueId:String?
    /** Your full JID for the room e.g. xmpp-development@conference.deusty.com/robbiehanson */
    @objc private var ownJID:String?
    
    /// JID of the room itself
    @objc private var jid:String?
    
    @objc open var preferredSecurity: RoomSecurity = .best
    
    /// XMPPJID of the room itself
    @objc public var roomJID: XMPPJID? {
        get {
            if let jid = jid {
                return XMPPJID(string: jid)
            } else {
                return nil
            }
        }
        set {
            jid = newValue?.bare
        }
    }
    
    
    public var ourJID: XMPPJID? {
        get {
            guard let jid = ownJID else {
                return nil
            }
            return XMPPJID(string: jid)
        }
        set {
            ownJID = newValue?.full
        }
    }

    @objc open var messageText:String?
    @objc open var lastRoomMessageId:String?
    @objc open var subject:String?
    @objc open var roomPassword:String?
    /// User state for the room, currently if we have viewed this room or not.
    /// Can be used to show information the first time we enter a room.
    @objc open var roomUserState:RoomUserState = .hasViewed

    // Transient properties stored in OTRBuddyCache
    @objc open var joined:Bool {
        get {
            return OTRBuddyCache.shared.runtimeProperties(for: self)?.joined ?? false
        }
        set (value) {
            OTRBuddyCache.shared.runtimeProperties(for: self)?.joined = value
        }
    }
    
    @objc open var hasFetchedHistory:Bool {
        get {
            return OTRBuddyCache.shared.runtimeProperties(for: self)?.hasFetchedHistory ?? false
        }
        set (value) {
            OTRBuddyCache.shared.runtimeProperties(for: self)?.hasFetchedHistory = value
        }
    }
    
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
    
    @objc override open class func storageBehaviorForProperty(withKey key:String) -> MTLPropertyStorage {
        if [#keyPath(hasFetchedHistory),
            #keyPath(joined),
            #keyPath(roomJID)].contains(key) {
            return MTLPropertyStorageNone
        }
        return super.storageBehaviorForProperty(withKey: key)
    }
}

extension OTRXMPPRoom:OTRThreadOwner {
    public func omemoDevices(with transaction: YapDatabaseReadTransaction) -> [OMEMODevice] {
        let occupants = allOccupants(transaction)
        let buddyKeys = occupants.compactMap { $0.buddyUniqueId }
        var devices: [OMEMODevice] = []
        buddyKeys.forEach { (buddyKey) in
            let buddyDevices = OMEMODevice.allDevices(forParentKey: buddyKey, collection: OTRXMPPBuddy.collection, transaction: transaction)
            devices.append(contentsOf: buddyDevices)
        }
        return devices
    }
    
    public func preferredTransportSecurity(with transaction: YapDatabaseReadTransaction) -> OTRMessageTransportSecurity {
        if !OTRSettingsManager.allowGroupOMEMO {
            return .plaintext
        }
        var transportSecurity = OTRMessageTransportSecurity.invalid
        switch preferredSecurity {
        case .best:
            transportSecurity = bestTransportSecurity(with: transaction)
        case .plaintext:
            transportSecurity = .plaintext
        case .omemo:
            transportSecurity = .OMEMO
        }
        return transportSecurity
    }
    
    // if we have keys for _any_ of the room occupants, we can do omemo
    // TODO: should we only do omemo if we have keys for _all_ occupants?
    public func bestTransportSecurity(with transaction: YapDatabaseReadTransaction) -> OTRMessageTransportSecurity {
        let devices = omemoDevices(with: transaction)
        if devices.count > 0 {
            return .OMEMO
        }
        return .plaintext
    }
    
    
    
    
    /** New outgoing message. Unsaved! */
    public func outgoingMessage(withText text: String, transaction: YapDatabaseReadTransaction) -> OTRMessageProtocol {
        let message = OTRXMPPRoomMessage()!
        message.messageText = text
        message.messageDate = Date()
        message.roomJID = self.jid
        message.roomUniqueId = self.uniqueId
        message.senderJID = self.ownJID
        message.state = .needsSending
        message.originId = message.xmppId ?? message.uniqueId
        let preferredSecurity = self.preferredTransportSecurity(with: transaction)
        message.messageSecurity = preferredSecurity
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


extension OTRXMPPRoom {
    
    @objc public var bookmark: XMPPConferenceBookmark? {
        guard let jid = roomJID else { return nil }
        let bookmark = XMPPConferenceBookmark(jid: jid, bookmarkName: self.subject, nick: nil, autoJoin: true)
        return bookmark
    }
    
}

extension OTRXMPPRoom: YapDatabaseRelationshipNode {
    
    /// return the OTRXMPPRoomOccupant.uniqueId for all room occupants
    public static func allOccupantKeys(roomUniqueId: String, transaction: YapDatabaseReadTransaction) -> [String] {
        var occupants: [String] = []
        guard let relationshipTransaction = transaction.ext(DatabaseExtensionName.relationshipExtensionName.name()) as? YapDatabaseRelationshipTransaction else {
            return []
        }
        relationshipTransaction.enumerateEdges(withName: OTRXMPPRoomOccupant.roomEdgeName, destinationKey: roomUniqueId, collection: OTRXMPPRoom.collection) { (edge, stop) in
            let sourceKey = edge.sourceKey
            assert(edge.sourceCollection == OTRXMPPRoomOccupant.collection, "Wrong collection!")
            occupants.append(sourceKey)
        }
        return occupants
    }
    
    public func allOccupants(_ transaction: YapDatabaseReadTransaction) -> [OTRXMPPRoomOccupant] {
        let occupants = OTRXMPPRoom.allOccupantKeys(roomUniqueId: self.uniqueId, transaction: transaction).compactMap {
            OTRXMPPRoomOccupant.fetchObject(withUniqueID: $0, transaction: transaction)
            }.filter {
                $0.jid != nil || $0.realJID != nil
        }
        return occupants
    }
    
    public func allBuddies(_ transaction: YapDatabaseReadTransaction) -> [OTRXMPPBuddy] {
        guard let account = account(with: transaction) as? OTRXMPPAccount else { return [] }
        let myJID = account.bareJID
        let buddies = allOccupants(transaction)
            .compactMap { $0.buddyUniqueId }
            .compactMap { OTRXMPPBuddy.fetchObject(withUniqueID: $0, transaction: transaction) }
        let filtered = buddies
        .filter { $0.bareJID != myJID }
        .sorted { $0.username < $1.username }
        return filtered
    }
    
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        guard let accountId = self.accountUniqueId else { return nil }
        let edgeName = YapDatabaseConstants.edgeName(.room)
        let edge = YapDatabaseRelationshipEdge(name: edgeName, destinationKey: accountId, collection: OTRXMPPAccount.collection, nodeDeleteRules: [YDB_NodeDeleteRules.deleteSourceIfDestinationDeleted])
        return [edge]
    }
}

extension XMPPRoom {
    
    /// yapKey for OTRXMPPRoom
    public var roomYapKey: String? {
        guard let accountId = self.accountId else {
            return nil
        }
        return accountId + roomJID.bare
    }
}

