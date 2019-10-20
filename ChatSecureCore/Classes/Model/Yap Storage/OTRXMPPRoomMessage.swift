//
//  OTRXMPPRoomMessage.swift
//  ChatSecure
//
//  Created by David Chiles on 10/19/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase
import CocoaLumberjack

@objc public enum RoomMessageState:Int {
    case received = 0 // incoming messages only
    case needsSending = 1
    case pendingSent = 2
    case sent = 3
    case delivered = 4 // counts as delivered if >1 receipts
    
    public func incoming() -> Bool {
        switch self {
        case .received: return true
        default: return false
        }
    }
}

open class OTRXMPPRoomMessage: OTRYapDatabaseObject {
    
    @objc public static let roomEdgeName = "OTRRoomMesageEdgeName"
    
    @objc open var roomJID:String?
    /** This is the full JID of the sender within the room. This should be equal to the occupant.jid*/
    @objc open var senderJID:String?
    
    /** This is the "real" JID of the non-anonymous buddy if it can be directly inferred from the message*/
    @objc private var _realJID:String?
    
    /** This is the "real" JID of the non-anonymous buddy if it can be directly inferred from the message*/
    open var realJID: XMPPJID? {
        get {
            guard let jid = _realJID else { return nil }
            return XMPPJID(string: jid)
        }
        set {
            _realJID = newValue?.full
        }
    }
    
    @objc open var state:RoomMessageState = .received
    @objc open var deliveredDate = Date.distantPast
    @objc open var messageText:String?
    @objc open var messageDate = Date.distantPast
    @objc open var xmppId:String? = UUID().uuidString
    @objc open var read = true
    @objc open var error:Error?
    @objc open var mediaItemId: String?
    @objc open var roomUniqueId:String?
    @objc open var originId:String?
    @objc open var stanzaId:String?
    @objc open var buddyUniqueId:String?
    /// this will either be plaintext or OMEMO
    @objc open var messageSecurityInfo: OTRMessageEncryptionInfo? = nil
    
    open override var hash: Int {
        get {
            return super.hash
        }
    }
}

extension OTRXMPPRoomMessage {
    public convenience init(message: XMPPMessage, delayed: Date?, room: OTRXMPPRoom, transaction: YapDatabaseReadTransaction) {
        self.init()
        xmppId = message.elementID
        messageText = message.body
        if let date = delayed {
            messageDate = date
        } else if let date = message.delayedDeliveryDate {
            messageDate = date
        } else {
            messageDate = Date()
        }
        senderJID = message.from?.full
        roomJID = room.roomJID?.bare
        // compare with lowercase-only because sometimes
        // we get both lowercase and uppercase nicknames?
        if room.ourJID?.full.lowercased() == message.from?.full.lowercased() {
            state = .sent
        } else {
            state = .received
        }
        roomUniqueId = room.uniqueId
        
        
        // Try to find buddy of sender. We might get an muc#user item element from where we can pull the real jid of the sender, else we try by message.senderJID.
        if let x = message.element(forName: "x", xmlns: XMPPMUCUserNamespace),
            let item = x.element(forName: "item"),
            let jidString = item.attribute(forName: "jid")?.stringValue,
            let jid = XMPPJID(string: jidString) {
            realJID = jid
        }
        // first try to scoop out buddy from realJID
        if let realJID = realJID,
             let accountId = room.accountUniqueId {
            if let buddy = OTRXMPPBuddy.fetchBuddy(jid: realJID, accountUniqueId: accountId, transaction: transaction)  {
                buddyUniqueId = buddy.uniqueId
            }
        }
        // if that fails, try to get an existing occupant
        if buddyUniqueId == nil,
            let accountId = room.accountUniqueId,
            let senderJID = message.from,
            let roomJID = room.roomJID,
            let occupant = OTRXMPPRoomOccupant.occupant(jid: senderJID, realJID: realJID, roomJID: roomJID, accountId: accountId, createIfNeeded: false, transaction: transaction) {
            buddyUniqueId = occupant.buddyUniqueId
        }
        
        read = false
    }
}

extension OTRXMPPRoomMessage:YapDatabaseRelationshipNode {
    //MARK: YapRelationshipNode
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        
        if let roomID = self.roomUniqueId {
            let relationship = YapDatabaseRelationshipEdge(name: OTRXMPPRoomMessage.roomEdgeName, sourceKey: self.uniqueId, collection: OTRXMPPRoomMessage.collection, destinationKey: roomID, collection: OTRXMPPRoom.collection, nodeDeleteRules: YDB_NodeDeleteRules.deleteSourceIfDestinationDeleted)
            return [relationship]
        }
        return nil
    }
}

extension OTRXMPPRoomMessage:OTRMessageProtocol {
    public func buddy(with transaction: YapDatabaseReadTransaction) -> OTRXMPPBuddy? {
        guard let uid = self.buddyUniqueId else {
            return nil
        }
        return OTRXMPPBuddy.fetchObject(withUniqueID: uid, transaction: transaction)
    }
    
    public func duplicateMessage() -> OTRMessageProtocol {
        let newMessage = OTRXMPPRoomMessage()!
        newMessage.messageText = self.messageText
        newMessage.messageError = self.messageError
        newMessage.messageMediaItemKey = self.messageMediaItemKey
        newMessage.roomUniqueId = self.roomUniqueId
        newMessage.roomJID = self.roomJID
        newMessage.senderJID = self.senderJID
        newMessage.messageSecurity = self.messageSecurity
        newMessage.state = .needsSending
        newMessage.xmppId = UUID().uuidString
        newMessage.originId = newMessage.xmppId
        return newMessage
    }
    
    public var isMessageSent: Bool {
        return state == .pendingSent
            || state == .sent
            || state == .delivered
    }
    
    public var isMessageDelivered: Bool {
        return deliveredDate > NSDate.distantPast
    }
    
    public var messageError: Error? {
        get {
            return self.error
        }
        set(messageError) {
            self.error = messageError
        }
    }

    //MARK: OTRMessageProtocol
    
    public var isMessageRead: Bool {
        return self.read
    }
    
    public var messageKey: String {
        return self.uniqueId
    }
    
    public var messageCollection: String {
        return OTRXMPPRoomMessage.collection
    }
    
    public var threadId: String {
        if let threadId = self.roomUniqueId {
            return threadId
        } else {
            DDLogError("RoomMessage is orphaned and not attached to a room! \(self.uniqueId)")
            // Returning empty string may prevent a crash, but is not ideal...
            return ""
        }
    }
    
    public var threadCollection: String {
        return OTRXMPPRoom.collection
    }
    
    public var isMessageIncoming: Bool {
        return self.state.incoming()
    }
    
    public var messageMediaItemKey: String? {
        get {
            return self.mediaItemId
        }
        set(messageMediaItemKey) {
            self.mediaItemId = messageMediaItemKey
        }
    }
    
    public var messageSecurity: OTRMessageTransportSecurity {
        get {
            return self.messageSecurityInfo?.messageSecurity ?? .plaintext;
        }
        set {
            self.messageSecurityInfo = OTRMessageEncryptionInfo(messageSecurity: newValue)
        }
    }
    
    public var remoteMessageId: String? {
        return self.xmppId
    }
    
    public func threadOwner(with transaction: YapDatabaseReadTransaction) -> OTRThreadOwner? {
        return OTRXMPPRoom.fetchObject(withUniqueID: self.threadId, transaction: transaction)
    }
}


public class OTRGroupDownloadMessage: OTRXMPPRoomMessage, OTRDownloadMessage {
    
    @objc private var parentMessageKey: String?
    @objc private var parentMessageCollection: String?
    @objc private var downloadURL: URL?
    
    public static func download(withParentMessage parentMessage: OTRMessageProtocol, url: URL) -> OTRDownloadMessage {
        let download = OTRGroupDownloadMessage()!
        if let parent = parentMessage as? OTRXMPPRoomMessage {
            download.buddyUniqueId = parent.buddyUniqueId
        }
        download.downloadURL = url
        download.parentMessageKey = parentMessage.messageKey
        download.parentMessageCollection = parentMessage.messageCollection
        download.messageText = url.absoluteString
        download.messageSecurity = parentMessage.messageSecurity
        download.messageDate = parentMessage.messageDate
        download.roomUniqueId = parentMessage.threadId
        if let groupMessage = parentMessage as? OTRXMPPRoomMessage {
            download.senderJID = groupMessage.senderJID
            download.roomJID = groupMessage.roomJID
        }
        return download
    }
    
    public override static var collection: String {
        return OTRXMPPRoomMessage.collection
    }
    
    public var url: URL? {
        if let url = self.downloadURL {
            return url
        } else if let urlString = self.messageText {
            return URL(string: urlString)
        }
        return nil
    }
    
    public func parentMessage(with transaction: YapDatabaseReadTransaction) -> OTRMessageProtocol? {
        if let message = parentObject(with: transaction) as? OTRMessageProtocol {
            return message
        } else {
            return nil
        }
    }
    
    public func touchParentMessage(with transaction: YapDatabaseReadWriteTransaction) {
        touchParentObject(with: transaction)
    }
    
    public var parentObjectKey: String? {
        get {
            return self.parentMessageKey
        }
        set {
            self.parentMessageKey = newValue
        }
    }
    
    public var parentObjectCollection: String? {
        get {
            return self.parentMessageCollection
        }
        set {
            self.parentMessageCollection = newValue
        }
    }
    
    public func parentObject(with transaction: YapDatabaseReadTransaction) -> Any? {
        guard let key = self.parentMessageKey, let collection = self.parentMessageCollection else {
            return nil
        }
        let object = transaction.object(forKey: key, inCollection: collection)
        return object
    }
    
    public func touchParentObject(with transaction: YapDatabaseReadWriteTransaction) {
        guard let key = self.parentMessageKey, let collection = self.parentMessageCollection else {
            return
        }
        transaction.touchObject(forKey: key, inCollection: collection)
    }
    
    //MARK: YapRelationshipNode
    public override func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        var edges: [YapDatabaseRelationshipEdge] = []
        if let superEdges = super.yapDatabaseRelationshipEdges() {
            edges.append(contentsOf: superEdges)
        }
        if let parentKey = self.parentMessageKey, let parentCollection = self.parentMessageCollection {
            let edgeName = RelationshipEdgeName.download.name()
            let parentEdge = YapDatabaseRelationshipEdge(name: edgeName, destinationKey: parentKey, collection: parentCollection, nodeDeleteRules: [.notifyIfSourceDeleted, .notifyIfDestinationDeleted])
            edges.append(parentEdge)
        }
        return edges
    }
}

extension OTRXMPPRoomMessage: OTRDownloadMessageProtocol {
    public func downloads() -> [OTRDownloadMessage] {
        guard self.isMessageIncoming else {
            return []
        }
        var downloads: [OTRDownloadMessage] = []
        for url in self.downloadableURLs {
            let download = OTRGroupDownloadMessage.download(withParentMessage: self, url: url)
            downloads.append(download)
        }
        return downloads
    }
    
    public func existingDownloads(with transaction: YapDatabaseReadTransaction) -> [OTRDownloadMessage] {
        guard self.isMessageIncoming else {
            return []
        }
        var downloads: [OTRDownloadMessage] = []
        let extensionName = YapDatabaseConstants.extensionName(.relationshipExtensionName)
        guard let relationship = transaction.ext(extensionName) as? YapDatabaseRelationshipTransaction else {
            DDLogWarn("\(extensionName) not registered!");
            return []
        }
        let edgeName = YapDatabaseConstants.edgeName(.download)
        relationship.enumerateEdges(withName: edgeName, destinationKey: self.messageKey, collection: self.messageCollection) { (edge, stop) in
            if let download = OTRGroupDownloadMessage.fetchObject(withUniqueID: edge.sourceKey, transaction: transaction) {
                downloads.append(download)
            }
        }
        return downloads
    }
    
    public func hasExistingDownloads(with transaction: YapDatabaseReadTransaction) -> Bool {
        guard self.isMessageIncoming else {
            return false
        }
        let extensionName = YapDatabaseConstants.extensionName(.relationshipExtensionName)
        guard let relationship = transaction.ext(extensionName) as? YapDatabaseRelationshipTransaction else {
            DDLogWarn("\(extensionName) not registered!");
            return false
        }
        let edgeName = YapDatabaseConstants.edgeName(.download)
        let count = relationship.edgeCount(withName: edgeName, destinationKey: self.messageKey, collection: self.messageCollection)
        return count > 0
    }
}


extension OTRXMPPRoomMessage:JSQMessageData {
    //MARK: JSQMessageData Protocol methods
    
    public func senderId() -> String! {
        var result:String? = nil
        OTRDatabaseManager.sharedInstance().uiConnection?.read { (transaction) -> Void in
            if (self.state.incoming()) {
                result = self.senderJID
            } else {
                guard let thread = transaction.object(forKey: self.threadId, inCollection: OTRXMPPRoom.collection) as? OTRXMPPRoom else {
                    return
                }
                result = thread.accountUniqueId
            }
        }
        assert(result != nil)
        return result
    }
    
    public func senderDisplayName() -> String! {
        if let sender = self.senderJID, let jid = XMPPJID(string: sender), let resource = jid.resource {
            return resource
        }
        return self.senderJID ?? ""
    }
    
    public func date() -> Date {
        return self.messageDate
    }
    
    public func isMediaMessage() -> Bool {
        if self.messageMediaItemKey != nil {
            return true
        }
        return false
    }
    
    public func messageHash() -> UInt {
        return UInt(bitPattern: self.uniqueId.hash)
    }
    
    public func text() -> String? {
        return self.messageText
    }
    
    public func messageRead() -> Bool {
        return self.read
    }
    
    public func media() -> JSQMessageMediaData? {
        guard let mediaId = self.mediaItemId else {
            return nil
        }
        var media: JSQMessageMediaData? = nil
        OTRDatabaseManager.shared.uiConnection?.read({ (transaction) in
            media = OTRMediaItem.fetchObject(withUniqueID: mediaId, transaction: transaction)
        })
        return media
    }
    
}

extension OTRXMPPRoomMessage {
    
    public func room(_ transaction: YapDatabaseReadTransaction) -> OTRXMPPRoom? {
        return threadOwner(with: transaction) as? OTRXMPPRoom
    }
    
    /// Getting all buddies for a room message to faciliate OMEMO group encryption
    public func allBuddyKeysForOutgoingMessage(_ transaction: YapDatabaseReadTransaction) -> [String] {
        guard let roomId = roomUniqueId else {
            return []
        }
        
        let buddyKeys = OTRXMPPRoom.allOccupantKeys(roomUniqueId: roomId, transaction: transaction).compactMap {
            OTRXMPPRoomOccupant.fetchObject(withUniqueID: $0, transaction: transaction)
            }.compactMap {
            $0.buddyUniqueId
        }
        
        return buddyKeys
    }
}

// MARK: Delivery receipts
extension OTRXMPPRoomMessage {
    /// Marks our sent messages as delivered when we receive a matching receipt
    @objc public static func handleDeliveryReceiptResponse(message: XMPPMessage, writeConnection: YapDatabaseConnection) {
        guard message.isGroupChatMessage,
            message.hasReceiptResponse,
            !message.isErrorMessage,
            let messageId = message.receiptResponseID else {
            return
        }
        writeConnection.asyncReadWrite { (transaction) in
            var roomMessage: OTRXMPPRoomMessage? = nil
            transaction.enumerateMessages(elementId: messageId, originId: message.originId, stanzaId: nil) { (messageProtocol, stop) in
                if let message = messageProtocol as? OTRXMPPRoomMessage {
                    roomMessage = message
                    stop.pointee = true
                }
            }
            // Mark messages as delivered, that aren't previous incoming messages
            if let deliveredMessage = roomMessage?.refetch(with: transaction),
                !deliveredMessage.isMessageIncoming {
                deliveredMessage.state = .delivered
                deliveredMessage.deliveredDate = Date()
                deliveredMessage.save(with: transaction)
            }
        }
    }
    
    /// Sends a response receipt when receiving a delivery receipt request
    @objc public static func handleDeliveryReceiptRequest(message: XMPPMessage, xmppStream:XMPPStream) {
        guard message.hasReceiptRequest,
            !message.hasReceiptResponse,
        let response = message.generateReceiptResponse else {
            return
        }
        // Don't send receipts for messages that you've sent
        if message.mucUserJID == xmppStream.myJID?.bareJID {
            return
        }
        xmppStream.send(response)
    }

}

extension XMPPRoom {
    @objc public func sendRoomMessage(_ message: OTRXMPPRoomMessage) {
        let elementId = message.xmppId ?? message.uniqueId
        let body = XMLElement(name: "body", stringValue: message.messageText)
        let xmppMessage = XMPPMessage(messageType: nil, to: nil, elementID: elementId, child: body)
        xmppMessage.addReceiptRequest()
        let originId = message.originId ?? message.xmppId ?? message.uniqueId
        xmppMessage.addOriginId(originId)
        send(xmppMessage)
    }
}

extension XMPPMessage {
    /// Gets the non-anonymous user JID from MUC message
    /// <x xmlns="http://jabber.org/protocol/muc#user"><item jid="user@example.com" affiliation="member" role="participant"/></x>
    public var mucUserJID: XMPPJID? {
        let x = element(forName: "x", xmlns: "http://jabber.org/protocol/muc#user")
        let item = x?.element(forName: "item")
        guard let jidString = item?.attributeStringValue(forName: "jid") else {
            return nil
        }
        return XMPPJID(string: jidString)
    }
}
