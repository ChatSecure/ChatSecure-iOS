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
    
    /// elementId is the XMPP elementId, originId and stanzaId are from XEP-0359
    @objc public func enumerateMessages(elementId:String?, originId: String?, stanzaId:String?, block:@escaping (_ message:OTRMessageProtocol,_ stop:UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let secondaryIndexTransaction = self.ext(OTRMessagesSecondaryIndex) as? YapDatabaseSecondaryIndexTransaction else {
            return
        }
        
        var parameters: [String] = []
        var queryString = ""
        let addQuery: ((_ column: String, _ value: String?) -> Void) = { (column, value) in
            guard let value = value else { return }
            var stringStart = "WHERE"
            if parameters.count > 0 {
                stringStart = " OR"
            }
            queryString += "\(stringStart) \(column) = ?"
            parameters.append(value)
        }
        addQuery(OTRYapDatabaseRemoteMessageIdSecondaryIndexColumnName, elementId)
        addQuery(SecondaryIndexName.originId, originId)
        addQuery(SecondaryIndexName.stanzaId, stanzaId)
        guard parameters.count > 0, queryString.characters.count > 0 else {
            return
        }
        let query = YapDatabaseQuery(string: queryString, parameters: parameters)
        
        secondaryIndexTransaction.enumerateKeys(matching: query) { (collection, key, stop) -> Void in
            if let message = self.object(forKey: key, inCollection: collection) as? OTRMessageProtocol {
                block(message, stop)
            }
        }
    }
    
    @objc public func enumerateSessions(accountKey:String, signalAddressName:String, block:@escaping (_ session:OTRSignalSession,_ stop:UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let secondaryIndexTransaction = self.ext(DatabaseExtensionName.secondaryIndexName.name()) as? YapDatabaseSecondaryIndexTransaction else {
            return
        }
        let queryString = "Where \(OTRYapDatabaseSignalSessionSecondaryIndexColumnName) = ?"
        let query = YapDatabaseQuery(string: queryString, parameters: ["\(accountKey)-\(signalAddressName)"])
        secondaryIndexTransaction.enumerateKeys(matching: query) { (collection, key, stop) -> Void in
            if let session = self.object(forKey: key, inCollection: collection) as? OTRSignalSession {
                block(session, stop)
            }
        }
    }
    
    /** The jid here is the full jid not real jid or nickname */
    @objc public func enumerateRoomOccupants(jid:String, block:@escaping (_ occupant:OTRXMPPRoomOccupant, _ stop:UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let secondaryIndexTransaction = self.ext(DatabaseExtensionName.secondaryIndexName.name()) as? YapDatabaseSecondaryIndexTransaction else {
            return
        }
        
        let queryString = "Where \(OTRYapDatabaseRoomOccupantJidSecondaryIndexColumnName) = ?"
        let query = YapDatabaseQuery(string: queryString, parameters: [jid])
        
        secondaryIndexTransaction.enumerateKeys(matching: query) { (collection, key, stop) -> Void in
            if let occupant = self.object(forKey: key, inCollection: collection) as? OTRXMPPRoomOccupant {
                block(occupant, stop)
            }
        }
    }
    
    @objc public func numberOfUnreadMessages() -> UInt {
        guard let secondaryIndexTransaction = self.ext(OTRMessagesSecondaryIndex) as? YapDatabaseSecondaryIndexTransaction else {
            return 0
        }
        
        let queryString = "Where \(OTRYapDatabaseUnreadMessageSecondaryIndexColumnName) == 0"
        let query = YapDatabaseQuery(string: queryString, parameters: [])
        
        var count:UInt = 0
        let success = secondaryIndexTransaction.getNumberOfRows(&count, matching: query)
        if (!success) {
            NSLog("Error with global numberOfUnreadMessages index")
        }
        return count
    }
    
    @objc public func allUnreadMessagesForThread(_ thread:OTRThreadOwner) -> [OTRMessageProtocol] {
        guard let indexTransaction = self.ext(OTRMessagesSecondaryIndex) as? YapDatabaseSecondaryIndexTransaction else {
            return []
        }
        let queryString = "Where \(OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName) == ? AND \(OTRYapDatabaseUnreadMessageSecondaryIndexColumnName) == 0"
        let query = YapDatabaseQuery(string: queryString, parameters: [thread.threadIdentifier])
        var result = [OTRMessageProtocol]()
        let success = indexTransaction.enumerateKeysAndObjects(matching: query) { (collection, key, object, stop) in
            if let message = object as? OTRMessageProtocol {
                result.append(message)
            }
        }
        
        if (!success) {
            NSLog("Query error for OTRXMPPRoom numberOfUnreadMessagesWithTransaction")
        }
        
        return result
    }
}

public extension YapDatabaseReadWriteTransaction {
    
    
    
}
