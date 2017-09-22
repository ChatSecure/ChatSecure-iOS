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
    case received = 0
    case needsSending = 1
    case pendingSent = 2
    case sent = 3
    
    public func incoming() -> Bool {
        switch self {
        case .received: return true
        default: return false
        }
    }
}

open class OTRXMPPRoomMessage: OTRYapDatabaseObject {
    
    open static let roomEdgeName = "OTRRoomMesageEdgeName"
    
    open var roomJID:String?
    
    /** This is the full JID of the sender. This should be equal to the occupant.jid*/
    open var senderJID:String?
    open var displayName:String?
    open var state:RoomMessageState = .received
    open var messageText:String?
    open var messageDate = Date.distantPast
    open var xmppId:String? = UUID().uuidString
    open var read = true
    open var error:Error?
    open var mediaItemId: String?
    
    open var roomUniqueId:String?
    
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
            fatalError("ThreadId should not be nil!")
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
        return .plaintext;
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
    
    public var url: URL {
        return self.downloadURL ?? URL(string: "")!
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
        return transaction.object(forKey: key, inCollection: collection)
    }
    
    public func touchParentObject(with transaction: YapDatabaseReadWriteTransaction) {
        guard let key = self.parentMessageKey, let collection = self.parentMessageCollection else {
            return
        }
        transaction.touchObject(forKey: key, inCollection: collection)
    }
}

extension OTRXMPPRoomMessage: OTRDownloadMessageProtocol {
    public func downloads() -> [OTRDownloadMessage] {
        var downloads: [OTRDownloadMessage] = []
        for url in self.downloadableURLs {
            let download = OTRGroupDownloadMessage.download(withParentMessage: self, url: url)
            downloads.append(download)
        }
        return downloads
    }
    
    public func existingDownloads(with transaction: YapDatabaseReadTransaction) -> [OTRDownloadMessage] {
        var downloads: [OTRDownloadMessage] = []
        let extensionName = DatabaseExtensionName.relationshipExtensionName
        guard let relationship = transaction.ext(extensionName) as? YapDatabaseRelationshipTransaction else {
            DDLogWarn("\(extensionName) not registered!");
            return []
        }
        let edgeName = RelationshipEdgeName.download
        relationship.enumerateEdges(withName: edgeName, destinationKey: self.messageKey, collection: self.messageCollection) { (edge, stop) in
            if let download = OTRGroupDownloadMessage.fetchObject(withUniqueID: edge.sourceKey, transaction: transaction) {
                downloads.append(download)
            }
        }
        return downloads
    }
    
    public func hasExistingDownloads(with transaction: YapDatabaseReadTransaction) -> Bool {
        let extensionName = DatabaseExtensionName.relationshipExtensionName
        guard let relationship = transaction.ext(extensionName) as? YapDatabaseRelationshipTransaction else {
            DDLogWarn("\(extensionName) not registered!");
            return false
        }
        let edgeName = RelationshipEdgeName.download
        let count = relationship.edgeCount(withName: edgeName)
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
