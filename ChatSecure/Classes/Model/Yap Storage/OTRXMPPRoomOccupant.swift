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
    @objc open var realJID:String? {
        didSet {
            if let realJid = self.realJID, let roomUniqueId = self.roomUniqueId {
                OTRDatabaseManager.shared.readOnlyDatabaseConnection?.asyncRead({ (transaction) in
                    if let room = OTRXMPPRoom.fetchObject(withUniqueID: roomUniqueId, transaction: transaction), let accountUniqueId = room.accountUniqueId {
                        self.realBuddy = OTRBuddy.fetch(withUsername: realJid, withAccountUniqueId: accountUniqueId, transaction: transaction)
                    }
                })
            }
        }
    }
    @objc open var realBuddy:OTRBuddy?
    
    @objc open var roomUniqueId:String?
    
    @objc open func avatarImage() -> UIImage {
        if let buddy = self.realBuddy {
            return OTRImages.avatarImage(withUniqueIdentifier: buddy.uniqueId, avatarData: nil, displayName: buddy.displayName, username: buddy.username)
        }
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
    
    // MARK: Disable Mantle Storage of Dynamic Properties
    
    override open class func encodingBehaviorsByPropertyKey() -> [AnyHashable:Any]? {
        var ret = super.encodingBehaviorsByPropertyKey()
        ret?["realBuddy"] = MTLModelEncodingBehaviorExcluded
        return ret
    }
    
    override open class func storageBehaviorForProperty(withKey propertyKey:String) -> MTLPropertyStorage {
        if propertyKey.compare("realBuddy") == .orderedSame {
            return MTLPropertyStorageNone
        }
        return super.storageBehaviorForProperty(withKey: propertyKey)
    }
}
