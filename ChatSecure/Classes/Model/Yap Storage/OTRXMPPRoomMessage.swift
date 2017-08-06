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
    //MARK: OTRMessageProtocol
    
    public var isMessageRead: Bool {
        return self.read
    }
    
    public var messageKey: String {
        return self.uniqueId
    }
    
    public var messageCollection: String {
        return type(of: self).collection
    }
    
    public var threadId: String? {
        return self.roomUniqueId
    }
    
    public var threadCollection: String {
        return OTRXMPPRoom.collection
    }
    
    public var isMessageIncoming: Bool {
        return self.state.incoming()
    }
    
    public var messageMediaItemKey: String? {
        return nil
    }
    
    public var messageError: Error? {
        return nil
    }
    
    public var messageSecurity: OTRMessageTransportSecurity {
        return .plaintext;
    }
    
    public var remoteMessageId: String? {
        return self.xmppId
    }
    
    public func threadOwner(with transaction: YapDatabaseReadTransaction) -> OTRThreadOwner? {
        guard let key = self.threadId else {
            return nil
        }
        return OTRXMPPRoom.fetchObject(withUniqueID: key, transaction: transaction)
    }
}

extension OTRXMPPRoomMessage: OTRDownloadMessageProtocol {
    public func downloads() -> [OTRDownloadMessage] {
        var downloads: [OTRDownloadMessage] = []
        for url in self.downloadableURLs {
            let download = OTRDownloadMessage(parentMessage: self, url: url)
            downloads.append(download)
        }
        return downloads
    }
    
    public func existingDownloads(with transaction: YapDatabaseReadTransaction) -> [OTRDownloadMessage] {
        var downloads: [OTRDownloadMessage] = []
        let extensionName = YapDatabaseConstants.extensionName(.relationshipExtensionName)
        guard let relationship = transaction.ext(extensionName) as? YapDatabaseRelationshipTransaction else {
            DDLogWarn("\(extensionName) not registered!");
            return []
        }
        let edgeName = YapDatabaseConstants.edgeName(.download)
        relationship.enumerateEdges(withName: edgeName, destinationKey: self.messageKey, collection: self.messageCollection) { (edge, stop) in
            if let download = OTRDownloadMessage.fetchObject(withUniqueID: edge.sourceKey, transaction: transaction) {
                downloads.append(download)
            }
        }
        return downloads
    }
    
    public func hasExistingDownloads(with transaction: YapDatabaseReadTransaction) -> Bool {
        let extensionName = YapDatabaseConstants.extensionName(.relationshipExtensionName)
        guard let relationship = transaction.ext(extensionName) as? YapDatabaseRelationshipTransaction else {
            DDLogWarn("\(extensionName) not registered!");
            return false
        }
        let edgeName = YapDatabaseConstants.edgeName(.download)
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
                guard let key = self.threadId, let thread = transaction.object(forKey: key, inCollection: OTRXMPPRoom.collection) as? OTRXMPPRoom else {
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
    
}
