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

extension RoomOccupantRole {
    public init(stringValue: String) {
        self = RoomOccupantRoleHelper.role(withString: stringValue)
    }
}

// Helper class to create from string, callable from obj-c
@objc public class RoomOccupantRoleHelper: NSObject {
    @objc public static func role(withString role:String) -> RoomOccupantRole {
        switch role {
        case "moderator":
            return RoomOccupantRole.moderator
        case "participant":
            return RoomOccupantRole.participant
        case "visitor":
            return RoomOccupantRole.visitor
        default:
            return RoomOccupantRole.none
        }
    }
}

@objc public enum RoomOccupantAffiliation:Int {
    case none = 0
    case outcast = 1
    case member = 2
    case admin = 3
    case owner = 4
    /// Value used when updating the DB. This enables us to remove occupants that used to be
    /// members, admins or owners, but are no longer that (e.g. they may have been kicked).
    /// Before fetching the lists for room [members, admins, owners] we mark all existing
    /// [members, admins, owners] as 'transient'. We then update the database from the lists.
    /// After this, we remove all occupants with affiliation 'transient', since they are no
    /// longer in the lists (or their affiliation would have been updated).
    case transient = 99
    
    public func isOwner() -> Bool {
        switch self {
        case .owner: return true
        default: return false
        }
    }
    
    public init(stringValue: String) {
        self = RoomOccupantAffiliationHelper.affiliation(withString: stringValue)
    }
    
    public var stringValue:String {
        get {
            switch self {
            case .owner: return "owner"
            case .admin: return "admin"
            case .member: return "member"
            case .outcast: return "outcast"
            default: return "none"
            }
        }
    }
}

// Helper class to create from string, callable from obj-c
@objc public class RoomOccupantAffiliationHelper: NSObject {
    @objc public static func affiliation(withString affiliation:String) -> RoomOccupantAffiliation {
        switch affiliation {
        case "owner":
            return RoomOccupantAffiliation.owner
        case "admin":
            return RoomOccupantAffiliation.admin
        case "member":
            return RoomOccupantAffiliation.member
        case "outcast":
            return RoomOccupantAffiliation.outcast
        default:
            return RoomOccupantAffiliation.none
        }
    }
}

open class OTRXMPPRoomOccupant: OTRYapDatabaseObject {
    
    @objc public static let roomEdgeName = "OTRRoomOccupantEdgeName"
    
    /** This is the JID of the participant as it's known in the room i.e. baseball_chat@conference.dukgo.com/user123 */
    @objc private var _jid: String?
    
    /** This is the JID of the participant as it's known in the room i.e. baseball_chat@conference.dukgo.com/user123 */
    @objc open var jid: XMPPJID? {
        get {
            guard let jidString = _jid else {
                return nil
            }
            return XMPPJID(string: jidString)
        }
        set {
            _jid = newValue?.full
        }
    }
    
    /** Aka "nickname". This is the name your known as in the room. Seems to be username without domain */
    @objc open var roomName:String? {
        return jid?.resource
    }
    
    /** This is the role of the occupant in the room */
    @objc open var role:RoomOccupantRole = .none

    /** This is the affiliation of the occupant in the room */
    @objc open var affiliation:RoomOccupantAffiliation = .none

    @objc private var _realJID:String?
    
    /** When given by the server we get the room participants real JID*/
    @objc open var realJID:XMPPJID? {
        get {
            guard let jidString = _realJID else {
                return nil
            }
            return XMPPJID(string: jidString)?.bareJID
        }
        set {
            _realJID = newValue?.bare
        }
    }


    @objc open var buddyUniqueId:String?
    @objc open var roomUniqueId:String?
    
    // jid is the full JID of the room participant e.g. baseball_chat@conference.dukgo.com/user123
    @objc public convenience init(jid: XMPPJID?, roomUniqueId: String) {
        self.init()
        _jid = jid?.full
        self.roomUniqueId = roomUniqueId
    }
    
    @objc open func avatarImage() -> UIImage {
        return OTRImages.avatarImage(withUniqueIdentifier: self.uniqueId, avatarData: nil, displayName: roomName, username: self.realJID?.full)
    }
    
    // MARK: Helper Functions

    @objc open func buddy(with transaction: YapDatabaseReadTransaction) -> OTRXMPPBuddy? {
        if let buddyUniqueId = self.buddyUniqueId {
            return OTRXMPPBuddy.fetchObject(withUniqueID: buddyUniqueId, transaction: transaction)
        }
        return nil
    }
    
    // MARK: MTLModel Overrides
    
    open override func decodeValue(forKey key: String!, with coder: NSCoder!, modelVersion: UInt) -> Any! {
        if modelVersion == 0 {
            if key == "_jid",
                let jid = coder.decodeObject(forKey: "jid") as? String {
                return jid
            } else if key == "_realJID",
                let realJID = coder.decodeObject(forKey: "realJID") as? String {
                return realJID
            }
        } else if modelVersion == 1 {
            if key == "_jid",
                let jids = coder.decodeObject(forKey: "jids") as? [String] {
                return jids.first
            } else if key == "_realJID",
                let realJID = coder.decodeObject(forKey: "realJID") as? String {
                return realJID
            }
        }
        return super.decodeValue(forKey: key, with: coder, modelVersion: modelVersion)
    }
    
    open class override func modelVersion() -> UInt {
        return 2
    }
    
    @objc override open class func storageBehaviorForProperty(withKey key:String) -> MTLPropertyStorage {
        if [#keyPath(jid),
            #keyPath(roomName),
            #keyPath(realJID)].contains(key) {
            return MTLPropertyStorageNone
        }
        return super.storageBehaviorForProperty(withKey: key)
    }
}

// MARK: YapDatabaseRelationshipNode Methods
extension OTRXMPPRoomOccupant: YapDatabaseRelationshipNode {
    open func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        if let roomID = self.roomUniqueId {
            let relationship = YapDatabaseRelationshipEdge(name: OTRXMPPRoomOccupant.roomEdgeName, sourceKey: self.uniqueId, collection: OTRXMPPRoomOccupant.collection, destinationKey: roomID, collection: OTRXMPPRoom.collection, nodeDeleteRules: YDB_NodeDeleteRules.deleteSourceIfDestinationDeleted)
            return [relationship]
        }
        return nil
    }
}

extension OTRXMPPRoomOccupant {
    
    
    /**
     * jid is the occupant's room JID
     * roomJID is the JID of the room itself
     * realJID is only available for non-anonymous rooms
     * createIfNeeded=true will return a new unsaved object if it's not found
     */
    @objc public static func occupant(jid: XMPPJID?,
                               realJID: XMPPJID?,
                               roomJID: XMPPJID,
                               accountId: String,
                               createIfNeeded: Bool,
                               transaction: YapDatabaseReadTransaction) -> OTRXMPPRoomOccupant? {
        assert(jid != nil || realJID != nil, "Cannot create occupant if both jid and realJID are nil!")
        // Bail out if both paramters are nil
        if jid == nil && realJID == nil {
            DDLogError("Cannot create occupant if both jid and realJID are nil!")
            return nil
        }
        let roomUniqueId = OTRXMPPRoom.createUniqueId(accountId, jid: roomJID.bare)
        guard let indexTransaction = transaction.ext(SecondaryIndexName.roomOccupants) as? YapDatabaseSecondaryIndexTransaction else {
            DDLogError("Error looking up OTRXMPPRoomOccupant via SecondaryIndex") 
            return nil
        }
        var matchingOccupants: [OTRXMPPRoomOccupant] = []
        
        var parameters: [String] = [roomUniqueId]
        var queryString = "Where \(RoomOccupantIndexColumnName.roomUniqueId) == ? AND ("
        if let jid = jid {
            parameters.append(jid.full)
            queryString.append("\(RoomOccupantIndexColumnName.jid) LIKE ?")
        }
        if jid != nil, realJID != nil {
            queryString.append(" OR ")
        }
        if let realJID = realJID {
            parameters.append(realJID.bare)
            queryString.append("\(RoomOccupantIndexColumnName.realJID) == ?")
        }
        queryString.append(")")
        
        let query = YapDatabaseQuery(string: queryString, parameters: parameters)
        let success = indexTransaction.enumerateKeysAndObjects(matching: query) { (collection, key, object, stop) in
            if let matchingOccupant = object as? OTRXMPPRoomOccupant,
                matchingOccupant.jid != nil || matchingOccupant.realJID != nil {
                matchingOccupants.append(matchingOccupant)
            }
        }
        if !success {
            DDLogError("Error looking up OTRXMPPRoomOccupant with query")
            return nil
        }
        if matchingOccupants.count > 1 {
            DDLogWarn("WARN: More than one OTRXMPPRoomOccupant matching query")

            // if we have a corrupted database with extra occupants, try to filter
            // out some of the bad ones
            let filtered = matchingOccupants.filter({ (occupant) -> Bool in
                occupant.jid != nil
            })
            if filtered.count > 0 {
                matchingOccupants = filtered
            }
        }
        var _occupant: OTRXMPPRoomOccupant? = matchingOccupants.first
        
        if _occupant == nil {
            if createIfNeeded {
                _occupant = OTRXMPPRoomOccupant(jid: jid, roomUniqueId: roomUniqueId)
            } else {
                return nil
            }
        } else {
            _occupant = _occupant?.copyAsSelf()
        }
        guard let occupant = _occupant else {
            return nil
        }
        
        // sometimes a bad database makes this nil
        if occupant.jid == nil, let jid = jid {
            occupant.jid = jid
        }
        
        // Set realJID?
        if let realJID = realJID {
            occupant.realJID = realJID
        }

        // While we're at it, match room occupant with a buddy on our roster if possible
        // This should probably be moved elsewhere
        if let realJID = occupant.realJID,
            let buddy = OTRXMPPBuddy.fetchBuddy(jid: realJID, accountUniqueId: accountId, transaction: transaction) {
            occupant.buddyUniqueId = buddy.uniqueId
        }
        return occupant
    }
}

// Extension to handle privileges
extension OTRXMPPRoomOccupant {
    public func canModifySubject() -> Bool {
        // TODO - Check muc#roomconfig_changesubject, participants may be allowed to change subject based on config!
        return self.role == .moderator || [RoomOccupantAffiliation.owner, RoomOccupantAffiliation.admin].contains(self.affiliation)
    }
    
    public func canInviteOthers() -> Bool {
        // TODO - participants may be allowed
        return self.role == .moderator || [RoomOccupantAffiliation.owner, RoomOccupantAffiliation.admin].contains(self.affiliation)
    }
    
    //https://xmpp.org/extensions/xep-0045.html#grantadmin
    //An owner can grant admin status to a member or an unaffiliated user; this is done by changing the user's affiliation to "admin":
    public func canGrantAdmin(_ occupant:OTRXMPPRoomOccupant) -> Bool {
        return self.affiliation == .owner && (occupant.affiliation == .member || occupant.affiliation == .none)
    }

    public func canRevokeMembership(_ occupant:OTRXMPPRoomOccupant) -> Bool {
        if occupant.affiliation == .owner {
            return false
        }
        if self.affiliation == .owner {
            return true
        }
        if self.affiliation == .admin && occupant.affiliation != .admin {
            return true
        }
        return false
    }

    //https://xmpp.org/extensions/xep-0045.html#ban
    //An admin or owner can ban one or more users from a room. The ban MUST be performed based on the occupant's bare JID. In order to ban a user, an admin MUST change the user's affiliation to "outcast".
    //As with Kicking an Occupant, a user cannot be banned by an admin with a lower affiliation. Therefore, if an admin attempts to ban an owner, the service MUST deny the request and return a <not-allowed/> error to the sender
    public func canBan(_ occupant:OTRXMPPRoomOccupant) -> Bool {
        return self.affiliation == .owner || (self.affiliation == .admin && occupant.affiliation != .owner)
    }
}
