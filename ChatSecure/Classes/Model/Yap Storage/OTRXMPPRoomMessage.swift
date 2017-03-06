//
//  OTRXMPPRoomMessage.swift
//  ChatSecure
//
//  Created by David Chiles on 10/19/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

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
    open var messageDate:Date?
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
            let relationship = YapDatabaseRelationshipEdge(name: OTRXMPPRoomMessage.roomEdgeName, sourceKey: self.uniqueId, collection: OTRXMPPRoomMessage.collection(), destinationKey: roomID, collection: OTRXMPPRoom.collection(), nodeDeleteRules: YDB_NodeDeleteRules.deleteSourceIfDestinationDeleted)
            return [relationship]
        }
        return nil
    }
}

extension OTRXMPPRoomMessage:OTRMessageProtocol {
    
    //MARK: OTRMessageProtocol
    
    public func messageKey() -> String {
        return self.uniqueId
    }
    
    public func messageCollection() -> String {
        return type(of: self).collection()
    }
    
    public func threadId() -> String? {
        return self.roomUniqueId
    }
    
    public func messageIncoming() -> Bool {
        return self.state.incoming()
    }
    
    public func messageMediaItemKey() -> String? {
        return nil
    }
    
    public func messageError() -> Error? {
        return nil
    }
    
    public func messageSecurity() -> OTRMessageTransportSecurity {
        return .plaintext;
    }
    
    public func remoteMessageId() -> String? {
        return self.xmppId
    }
    
    public func threadOwner(with transaction: YapDatabaseReadTransaction) -> OTRThreadOwner? {
        guard let key = self.threadId() else {
            return nil
        }
        return OTRXMPPRoom.fetchObject(withUniqueID: key, transaction: transaction)
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
                guard let key = self.threadId(), let thread = transaction.object(forKey: key, inCollection: OTRXMPPRoom.collection()) as? OTRXMPPRoom else {
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
        guard let date = self.messageDate else {
            return Date.distantPast
        }
        return date
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
