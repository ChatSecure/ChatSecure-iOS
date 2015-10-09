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
    
}

public class OTRXMPPRoom: OTRYapDatabaseObject, OTRThreadOwner {
    
    public var accountUniqueId:String?
    public var ownJID:String?
    public var jid:String?
    
    public func threadName() -> String {
        return self.jid ?? ""
    }
    
    public func threadIdentifier() -> String {
        return self.uniqueId
    }
    
    public func threadAccountIdentifier() -> String {
        return self.accountUniqueId ?? ""
    }
}

public class OTRXMPPRoomOccupant: OTRYapDatabaseObject, YapDatabaseRelationshipNode {
    
    public static let roomEdgeName = "OTRRoomOccupantEdgeName"
    
    public var available = false
    public var jid:String?
    
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

public class OTRXMPPRoomMessage: OTRYapDatabaseObject, YapDatabaseRelationshipNode, OTRMesssageProtocol {
    
    public static let roomEdgeName = "OTRRoomMesageEdgeName"
    
    public var roomJID:String?
    public var senderJID:String?
    public var incoming = false
    public var text:String?
    public var date:NSDate?
    
    public var roomUniqueId:String?
    
    //MARK: OTRMessagePRotocol
    public func messageDate() -> NSDate! {
        return self.date
    }
    
    public func ownerIdentifier() -> String! {
        return self.roomUniqueId
    }
    
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
