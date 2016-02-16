//
//  YapDatabaseReadTransaction+ChatSecure.swift
//  ChatSecure
//
//  Created by David Chiles on 10/27/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase.YapDatabaseSecondaryIndex

public extension YapDatabaseReadTransaction {
    
    public func enumerateMessages(id id:String, block:(message:OTRMesssageProtocol,stop:UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let secondaryIndexTransaction = self.ext(OTRYapDatabseSecondaryIndexExtension) as? YapDatabaseSecondaryIndexTransaction else {
            return
        }
        
        let queryString = "Where \(OTRYapDatabseMessageIdSecondaryIndex) = ?"
        let query = YapDatabaseQuery(string: queryString, parameters: [id])
        
        secondaryIndexTransaction.enumerateKeysMatchingQuery(query) { (collection, key, stop) -> Void in
            if let message = self.objectForKey(key, inCollection: collection) as? OTRMesssageProtocol {
                block(message: message, stop: stop)
            }
        }
    }
    
    /** The jid here is the full jid not real jid or nickname */
    public func enumerateRoomOccupants(jid jid:String, block:(occupant:OTRXMPPRoomOccupant, stop:UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let secondaryIndexTransaction = self.ext(OTRYapDatabseSecondaryIndexExtension) as? YapDatabaseSecondaryIndexTransaction else {
            return
        }
        
        let queryString = "Where \(OTRYapDatabseRoomOccupantJIdSecondaryIndex) = ?"
        let query = YapDatabaseQuery(string: queryString, parameters: [jid])
        
        secondaryIndexTransaction.enumerateKeysMatchingQuery(query) { (collection, key, stop) -> Void in
            if let occupant = self.objectForKey(key, inCollection: collection) as? OTRXMPPRoomOccupant {
                block(occupant: occupant, stop: stop)
            }
        }
    }
    
    public func numberOfUnreadMessages() -> UInt {
        guard let secondaryIndexTransaction = self.ext(OTRYapDatabseSecondaryIndexExtension) as? YapDatabaseSecondaryIndexTransaction else {
            return 0
        }
        
        let queryString = "Where \(OTRYapDatabaseUnreadMessageSecondaryIndex) = 0"
        let query = YapDatabaseQuery(string: queryString, parameters: [])
        
        var count:UInt = 0
        secondaryIndexTransaction.getNumberOfRows(&count, matchingQuery: query)
        return count
    }
}