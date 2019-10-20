//
//  YapDatabse+ChatSecure.swift
//  ChatSecure
//
//  Created by David Chiles on 10/20/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

@objc public extension OTRDatabaseManager {
    @objc var connections: DatabaseConnections? {
        guard let ui = uiConnection,
        let read = readConnection,
        let write = writeConnection,
            let long = longLivedReadOnlyConnection else {
                return nil
        }
        return DatabaseConnections(ui: ui, read: read, write: write, longLivedRead: long)
    }
}

/// This class holds shared references to commonly-needed Yap database connections
@objcMembers
public class DatabaseConnections: NSObject {
    
    /// User interface / synchronous main-thread reads only!
    public let ui: YapDatabaseConnection
    /// Background / async reads only! Not for use in main thread / UI code.
    public let read: YapDatabaseConnection
    /// Background writes only! Never use this synchronously from the main thread!
    public let write: YapDatabaseConnection
    /// This is only to be used by the YapViewHandler for main thread reads only!
    public let longLivedRead: YapDatabaseConnection
    
    init(ui: YapDatabaseConnection,
    read: YapDatabaseConnection,
    write: YapDatabaseConnection,
    longLivedRead: YapDatabaseConnection) {
        self.ui = ui
        self.read = read
        self.write = write
        self.longLivedRead = longLivedRead
    }
}

extension YapDatabase {
    
     @objc func asyncRegisterView(_ grouping:YapDatabaseViewGrouping, sorting:YapDatabaseViewSorting, version:String, whiteList:Set<String>, name:DatabaseExtensionName, completionQueue:DispatchQueue?, completionBlock:((Bool) ->Void)?) {
        
        if (self.registeredExtension(name.name()) != nil ) {
            let queue:DispatchQueue = completionQueue ?? DispatchQueue.main
            if let block = completionBlock {
                queue.async(execute: { () -> Void in
                    block(true)
                })
            }
            return
        }
        
        let options = YapDatabaseViewOptions()
        options.allowedCollections = YapWhitelistBlacklist(whitelist: whiteList)
        let view = YapDatabaseAutoView(grouping: grouping, sorting: sorting, versionTag: version, options: options)
        self.asyncRegister(view, withName: name.name(), completionQueue: completionQueue, completionBlock: completionBlock)
    }
    
    @objc public func asyncRegisterGroupOccupantsView(_ completionQueue:DispatchQueue?, completionBlock:((Bool) ->Void)?) {
        
        let grouping = YapDatabaseViewGrouping.withObjectBlock { (readTransaction, collection , key , object ) -> String? in
            guard let occupant = object as? OTRXMPPRoomOccupant else {
                return nil
            }
            
            guard let roomId = occupant.roomUniqueId else {
                return nil
            }
            
            // Filter out occupants not associated with any JIDs
            if occupant.jid == nil,
                occupant.realJID == nil {
                return nil
            }
            
            // Filter out outcasts and occupants that have affilition none and role none (which in private rooms means not a member and in public rooms means not currently in the room
            if occupant.affiliation == .outcast || (occupant.affiliation == .none && occupant.role == .none) {
                return nil
            }
            
            return roomId
        }
        
        let sorting = YapDatabaseViewSorting.withObjectBlock { (readTransaction, group, collection1, key1, object1, collection2, key2, object2) -> ComparisonResult in
            
            let affiliation1 = (object1 as? OTRXMPPRoomOccupant)?.affiliation ?? .none
            let affiliation2 = (object2 as? OTRXMPPRoomOccupant)?.affiliation ?? .none
            
            let obj1isImportant = (affiliation1 == RoomOccupantAffiliation.owner || affiliation1 == RoomOccupantAffiliation.admin)
            let obj2isImportant = (affiliation2 == RoomOccupantAffiliation.owner || affiliation2 == RoomOccupantAffiliation.admin)
            if obj1isImportant != obj2isImportant {
                if obj1isImportant {
                    return .orderedAscending
                } else {
                    return .orderedDescending
                }
            }
            
            guard let name1 = (object1 as? OTRXMPPRoomOccupant)?.roomName ?? (object1 as? OTRXMPPRoomOccupant)?.realJID?.full ?? (object1 as? OTRXMPPRoomOccupant)?.jid?.full else {
                return .orderedSame
            }
            
            guard let name2 = (object2 as? OTRXMPPRoomOccupant)?.roomName ?? (object2 as? OTRXMPPRoomOccupant)?.realJID?.full ?? (object2 as? OTRXMPPRoomOccupant)?.jid?.full else {
                return .orderedSame
            }
            
            return name1.localizedCompare(name2)
        }
        
        self.asyncRegisterView(grouping, sorting: sorting, version: "10", whiteList: [OTRXMPPRoomOccupant.collection], name: .groupOccupantsViewName, completionQueue: completionQueue, completionBlock: completionBlock)
    }
}
