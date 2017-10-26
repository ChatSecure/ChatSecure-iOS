//
//  OTRXMPPRoomOccupant.swift
//  ChatSecure
//
//  Created by David Chiles on 10/19/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

@objc public enum RoomOccupantRole:Int {
    case none = 0
    case participant = 1
    case moderator = 2
    case visitor = 3
    
    public func canModifySubject() -> Bool {
        switch self {
        case .moderator: return true // TODO - Check muc#roomconfig_changesubject, participants may be allowed to change subject based on config!
        default: return false
        }
    }
    
    public func canInviteOthers() -> Bool {
        switch self {
        case .moderator: return true // TODO - participants may be allowed
        default: return false
        }
    }
}

@objc public enum RoomOccupantAffiliation:Int {
    case none = 0
    case outcast = 1
    case member = 2
    case admin = 3
    case owner = 4
    
    public func isOwner() -> Bool {
        switch self {
        case .owner: return true
        default: return false
        }
    }
}

open class OTRXMPPRoomOccupant: OTRYapDatabaseObject, YapDatabaseRelationshipNode {
    
    @objc open static let roomEdgeName = "OTRRoomOccupantEdgeName"
    
    @objc open var available = false
    
    /** This is the JID of the participant as it's known in the room i.e. baseball_chat@conference.dukgo.com/user123 */
    @objc open var jid:String?
    
    /** This is the name your known as in the room. Seems to be username without domain */
    @objc open var roomName:String?
    
    /** This is the role of the occupant in the room */
    @objc open var role:RoomOccupantRole = .none

    /** This is the affiliation of the occupant in the room */
    @objc open var affiliation:RoomOccupantAffiliation = .none

    /**When given by the server we get the room participants reall JID*/
    @objc open var realJID:String?
    
    @objc open var roomUniqueId:String?
    
    @objc open func avatarImage() -> UIImage {
        return OTRImages.avatarImage(withUniqueIdentifier: self.uniqueId, avatarData: nil, displayName: roomName ?? realJID ?? jid, username: self.realJID)
    }
    
    //MARK: YapDatabaseRelationshipNode Methods
    open func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        if let roomID = self.roomUniqueId {
            let relationship = YapDatabaseRelationshipEdge(name: OTRXMPPRoomOccupant.roomEdgeName, sourceKey: self.uniqueId, collection: OTRXMPPRoomOccupant.collection, destinationKey: roomID, collection: OTRXMPPRoom.collection, nodeDeleteRules: YDB_NodeDeleteRules.deleteSourceIfDestinationDeleted)
            return [relationship]
        }
        return nil
    }
}
