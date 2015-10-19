//
//  OTRXMPPRoom.swift
//  ChatSecure
//
//  Created by David Chiles on 10/7/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import UIKit
import YapDatabase

@objc public protocol OTRThreadOwner: NSObjectProtocol {
    
    func threadName() -> String
    func threadIdentifier() -> String
    func threadAccountIdentifier() -> String
    func setCurrentMessageText(text:String?)
    func currentMessageText() -> String?
}

public class OTRXMPPRoom: OTRYapDatabaseObject, OTRThreadOwner {
    
    public var accountUniqueId:String?
    public var ownJID:String?
    public var jid:String?
    public var joined = false
    public var messageText:String?
    override public var uniqueId:String {
        get {
            if let account = self.accountUniqueId {
                if let jid = self.jid {
                    return OTRXMPPRoom.createUniqueId(account, jid: jid)
                }
            }
            return super.uniqueId
        }
    }
    
    public func threadName() -> String {
        return self.jid ?? ""
    }
    
    public func threadIdentifier() -> String {
        return self.uniqueId
    }
    
    public func threadAccountIdentifier() -> String {
        return self.accountUniqueId ?? ""
    }
    
    public func setCurrentMessageText(text: String?) {
        self.messageText = text
    }
    
    public func currentMessageText() -> String? {
        return self.messageText
    }
    
    public class func createUniqueId(accountId:String, jid:String) -> String {
        return accountId + jid
    }
}

public class OTRXMPPRoomOccupant: OTRYapDatabaseObject, YapDatabaseRelationshipNode {
    
    public static let roomEdgeName = "OTRRoomOccupantEdgeName"
    
    public var available = false
    
    /** This is the JID of the participant as it's known in teh room  ie baseball_chat@conference.dukgo.com/user123 */
    public var jid:String?
    
    /** This is the name your known as in the room. Seems to be username without domain */
    public var roomName:String?
    
    /**When given by the server we get the room participants reall JID*/
    public var realJID:String?
    
    public var roomUniqueId:String?
    
    public func yapDatabaseRelationshipEdges() -> [AnyObject]! {
        if let roomID = self.roomUniqueId {
            let relationship = YapDatabaseRelationshipEdge(name: OTRXMPPRoomOccupant.roomEdgeName, sourceKey: self.uniqueId, collection: OTRXMPPRoomOccupant.collection(), destinationKey: roomID, collection: OTRXMPPRoom.collection(), nodeDeleteRules: YDB_NodeDeleteRules.DeleteSourceIfDestinationDeleted)
            return [relationship]
        } else {
            return []
        }
    }
}

public class OTRXMPPRoomMessage: OTRYapDatabaseObject {
    
    public static let roomEdgeName = "OTRRoomMesageEdgeName"
    
    public var roomJID:String?
    
    /** This is the full JID of the sender. This should be equal to the occupant.jid*/
    public var senderJID:String?
    public var displayName:String?
    public var incoming = false
    public var messageText:String?
    public var messageDate:NSDate?
    
    public var roomUniqueId:String?
}

extension OTRXMPPRoomMessage:YapDatabaseRelationshipNode {
    //MARK: YapRelationshipNode
    public func yapDatabaseRelationshipEdges() -> [AnyObject]! {
        
        if let roomID = self.roomUniqueId {
            let relationship = YapDatabaseRelationshipEdge(name: OTRXMPPRoomMessage.roomEdgeName, sourceKey: self.uniqueId, collection: OTRXMPPRoomMessage.collection(), destinationKey: roomID, collection: OTRXMPPRoom.collection(), nodeDeleteRules: YDB_NodeDeleteRules.DeleteSourceIfDestinationDeleted)
            return [relationship]
        } else {
            return []
        }
    }
}

extension OTRXMPPRoomMessage:OTRMesssageProtocol {
    
    //MARK: OTRMessageProtocol
    
    public func messageIncoming() -> Bool {
        return self.incoming
    }
    
    public func messageMediaItemKey() -> String! {
        return nil
    }
    
    //MARK: JSQMessageData Protocol methods
    
    public func senderId() -> String! {
        return self.senderJID
    }
    
    public func senderDisplayName() -> String! {
        return self.displayName
    }
    
    public func date() -> NSDate! {
        return self.messageDate
    }
    
    public func isMediaMessage() -> Bool {
        return false
    }
    
    public func messageHash() -> UInt {
        if let hash = self.messageText?.hash {
            return UInt(hash)
        }
        return 0
    }
    
    public func text() -> String! {
        return self.messageText
    }
    
}
