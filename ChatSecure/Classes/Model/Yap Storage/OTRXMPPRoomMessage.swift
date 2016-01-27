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
    case Received = 0
    case NeedsSending = 1
    case PendingSent = 2
    case Sent = 3
    
    public func incoming() -> Bool {
        switch self {
        case .Received: return true
        default: return false
        }
    }
}

public class OTRXMPPRoomMessage: OTRYapDatabaseObject {
    
    public static let roomEdgeName = "OTRRoomMesageEdgeName"
    
    public var roomJID:String?
    
    /** This is the full JID of the sender. This should be equal to the occupant.jid*/
    public var senderJID:String?
    public var displayName:String?
    public var state:RoomMessageState = .Received
    public var messageText:String?
    public var messageDate:NSDate?
    public var xmppId:String? = NSUUID().UUIDString
    public var read = true
    
    public var roomUniqueId:String?
    
    public override var hash: Int {
        get {
            return super.hash
        }
    }
}

extension OTRXMPPRoomMessage:YapDatabaseRelationshipNode {
    //MARK: YapRelationshipNode
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        
        if let roomID = self.roomUniqueId {
            let relationship = YapDatabaseRelationshipEdge(name: OTRXMPPRoomMessage.roomEdgeName, sourceKey: self.uniqueId, collection: OTRXMPPRoomMessage.collection(), destinationKey: roomID, collection: OTRXMPPRoom.collection(), nodeDeleteRules: YDB_NodeDeleteRules.DeleteSourceIfDestinationDeleted)
            return [relationship]
        }
        return nil
    }
}

extension OTRXMPPRoomMessage:OTRMesssageProtocol {
    
    //MARK: OTRMessageProtocol
    
    public func messageKey() -> String! {
        return self.uniqueId
    }
    
    public func messageCollection() -> String! {
        return self.dynamicType.collection()
    }
    
    public func threadId() -> String! {
        return self.roomUniqueId
    }
    
    public func messageIncoming() -> Bool {
        return self.state.incoming()
    }
    
    public func messageMediaItemKey() -> String! {
        return nil
    }
    
    public func messageError() -> NSError! {
        return nil
    }
    
    public func transportedSecurely() -> Bool {
        return false;
    }
    
    public func remoteMessageId() -> String! {
        return self.xmppId
    }
    
    public func threadOwnerWithTransaction(transaction: YapDatabaseReadTransaction!) -> OTRThreadOwner! {
        return OTRXMPPRoom.fetchObjectWithUniqueID(self.threadId(), transaction: transaction)
    }
}


extension OTRXMPPRoomMessage:JSQMessageData {
    //MARK: JSQMessageData Protocol methods
    
    public func senderId() -> String! {
        var result:String? = nil
        OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.readWithBlock { (transaction) -> Void in
            if (self.state.incoming()) {
                result = self.senderJID
            } else {
                guard let thread = transaction.objectForKey(self.threadId(), inCollection: OTRXMPPRoom.collection()) as? OTRXMPPRoom else {
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
    
    public func date() -> NSDate! {
        return self.messageDate
    }
    
    public func isMediaMessage() -> Bool {
        return false
    }
    
    public func messageHash() -> UInt {
        
        //TODO this is not correct but UInt(self.hash) does not working
        return UInt(self.date().timeIntervalSince1970)
    }
    
    public func text() -> String! {
        return self.messageText
    }
    
    public func messageRead() -> Bool {
        return self.read
    }
    
}