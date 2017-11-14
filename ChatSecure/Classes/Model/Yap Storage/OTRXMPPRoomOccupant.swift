//
//  OTRXMPPRoomOccupant.swift
//  ChatSecure
//
//  Created by David Chiles on 10/19/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase
import Mantle
import CocoaLumberjack

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

    @objc open var buddyUniqueId:String?
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
    
    // MARK: Helper Functions

    @objc open func buddy(with transaction: YapDatabaseReadTransaction) -> OTRXMPPBuddy? {
        if let buddyUniqueId = self.buddyUniqueId {
            return OTRXMPPBuddy.fetchObject(withUniqueID: buddyUniqueId, transaction: transaction)
        }
        return nil
    }
    
}

public extension OTRXMPPRoomOccupant {
    /**
     * jid is the occupant's room JID
     * roomJID is the JID of the room itself
     * realJID is only available for non-anonymous rooms
     * createIfNeeded=true will return a new unsaved object if it's not found
     */
    @objc public static func occupant(jid: XMPPJID,
                               realJID: XMPPJID?,
                               roomJID: XMPPJID,
                               accountId: String,
                               createIfNeeded: Bool,
                               transaction: YapDatabaseReadTransaction) -> OTRXMPPRoomOccupant? {
        guard let indexTransaction = transaction.ext(SecondaryIndexName.roomOccupants) as? YapDatabaseSecondaryIndexTransaction else {
            DDLogError("Error looking up OTRXMPPRoomOccupant via SecondaryIndex")
            return nil
        }
        let roomUniqueId = OTRXMPPRoom.createUniqueId(accountId, jid: roomJID.bare)
        var matchingOccupants: [OTRXMPPRoomOccupant] = []
        
        var parameters: [String] = [roomUniqueId]
        var queryString = "Where \(RoomOccupantIndexColumnName.roomUniqueId) == ? AND ("
        parameters.append(jid.full)
        queryString.append("\(RoomOccupantIndexColumnName.jid) == ?")
        if let realJID = realJID {
            parameters.append(realJID.bare)
            queryString.append(" OR \(RoomOccupantIndexColumnName.realJID) == ?")
        }
        queryString.append(")")
        
        let query = YapDatabaseQuery(string: queryString, parameters: parameters)
        let success = indexTransaction.enumerateKeysAndObjects(matching: query) { (collection, key, object, stop) in
            if let matchingOccupant = object as? OTRXMPPRoomOccupant {
                matchingOccupants.append(matchingOccupant)
            }
        }
        if !success {
            DDLogError("Error looking up OTRXMPPRoomOccupant with query \(query)")
            return nil
        }
        if matchingOccupants.count > 1 {
            DDLogWarn("WARN: More than one OTRXMPPRoomOccupant matching query \(query): \(matchingOccupants)")
        }
        var occupant: OTRXMPPRoomOccupant? = matchingOccupants.first
        var didCreate = false
        
        if occupant == nil,
            createIfNeeded {
            occupant = OTRXMPPRoomOccupant()!
            occupant?.jid = jid.full
            occupant?.realJID = realJID?.bare
            occupant?.roomUniqueId = roomUniqueId
            didCreate = true
        }
        
        // While we're at it, match room occupant with a buddy on our roster if possible
        // This should probably be moved elsewhere
        if let existingOccupant = occupant,
            let realJID = existingOccupant.realJID,
            let jid = XMPPJID(string: realJID),
            existingOccupant.buddyUniqueId == nil,
            let buddy = OTRXMPPBuddy.fetchBuddy(jid: jid, accountUniqueId: accountId, transaction: transaction) {
            if !didCreate {
                occupant = existingOccupant.copy() as? OTRXMPPRoomOccupant
            }
            occupant?.buddyUniqueId = buddy.uniqueId
        }
        
        return occupant
    }
}
