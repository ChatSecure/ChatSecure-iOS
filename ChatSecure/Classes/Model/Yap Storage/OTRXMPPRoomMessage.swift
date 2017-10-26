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
    
    @objc open static let roomEdgeName = "OTRRoomMesageEdgeName"
    
    @objc open var roomJID:String?
    /** This is the full JID of the sender. This should be equal to the occupant.jid*/
    @objc open var senderJID:String?
    @objc open var displayName:String?
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
    
    open override var hash: Int {
        get {
            return super.hash
        }
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
    public func duplicateMessage() -> OTRMessageProtocol {
        let newMessage = OTRXMPPRoomMessage()!
        newMessage.messageText = self.messageText
        newMessage.messageError = self.messageError
        newMessage.messageMediaItemKey = self.messageMediaItemKey
        newMessage.roomUniqueId = self.roomUniqueId
        newMessage.roomJID = self.roomJID
        newMessage.senderJID = self.senderJID
        newMessage.displayName = self.displayName
        newMessage.messageSecurity = self.messageSecurity
        newMessage.state = .needsSending
        newMessage.xmppId = UUID().uuidString
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
            return .plaintext;
        }
        set {
            // currently only plaintext is supported
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
    
    private var parentMessageKey: String?
    private var parentMessageCollection: String?
    private var downloadURL: URL?
    
    public static func download(withParentMessage parentMessage: OTRMessageProtocol, url: URL) -> OTRDownloadMessage {
        let download = OTRGroupDownloadMessage()!
        
        download.downloadURL = url
        download.parentMessageKey = parentMessage.messageKey
        download.parentMessageCollection = parentMessage.messageCollection
        download.messageText = url.absoluteString
        download.messageDate = parentMessage.messageDate
        download.roomUniqueId = parentMessage.threadId
        if let groupMessage = parentMessage as? OTRXMPPRoomMessage {
            download.senderJID = groupMessage.senderJID
            download.displayName = groupMessage.displayName
            download.roomJID = groupMessage.roomJID
        }
        return download
    }
    
    public override static var collection: String {
        return OTRXMPPRoomMessage.collection
    }
    
    public var url: URL? {
        return self.downloadURL
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
        OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection?.read { (transaction) -> Void in
            if (self.state.incoming()) {
                result = self.senderJID
            } else {
                guard let thread = transaction.object(forKey: self.threadId, inCollection: OTRXMPPRoom.collection) as? OTRXMPPRoom else {
                    return
                }
                result = thread.accountUniqueId
            }
        }
        return result
    }
    
    public func senderDisplayName() -> String! {
        return self.displayName ?? ""
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
        OTRDatabaseManager.shared.readOnlyDatabaseConnection?.read({ (transaction) in
            media = OTRMediaItem.fetchObject(withUniqueID: mediaId, transaction: transaction)
        })
        return media
    }
    
}

public extension OTRXMPPRoomMessage {
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
        xmppStream.send(response)
    }

}
