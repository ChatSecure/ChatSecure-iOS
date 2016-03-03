//
//  PushMessage.swift
//  ChatSecure
//
//  Created by David Chiles on 3/1/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

///A simple message object to mark when push or knock messages were sent off
public class PushMessage: OTRYapDatabaseObject {
    
    /// The buddy the knock was sent to
    public var buddyKey:String?
    
    /// Any error from the ChatSecure-Push-Server
    public var error:NSError?
    
    /// the date the push was sent, used for sorting
    public var pushDate:NSDate = NSDate()
    
    ///Send it to the same collection of other messages
    public class override func collection() -> String {
        return OTRMessage.collection()
    }
    
}

extension PushMessage: OTRMessageProtocol {
    public func messageKey() -> String! {
        return self.uniqueId
    }
    
    public func messageCollection() -> String! {
        return OTRMessage.collection()
    }
    
    public func threadId() -> String! {
        return self.buddyKey
    }
    
    public func messageIncoming() -> Bool {
        return false
    }
    
    public func messageMediaItemKey() -> String! {
        return nil
    }
    
    public func messageError() -> NSError! {
        return self.error
    }
    
    public func transportedSecurely() -> Bool {
        return false
    }
    
    public func messageRead() -> Bool {
        return true
    }
    
    public func date() -> NSDate! {
        return self.pushDate
    }
    
    public func text() -> String! {
        return nil
    }
    
    public func remoteMessageId() -> String! {
        return nil
    }
    
    public func threadOwnerWithTransaction(transaction: YapDatabaseReadTransaction!) -> OTRThreadOwner! {
        return OTRBuddy.fetchObjectWithUniqueID(self.buddyKey, transaction: transaction)
    }
}

extension PushMessage: YapDatabaseRelationshipNode {
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        
        if let destinationKey = self.buddyKey {
            let name = "buddy"
            return [YapDatabaseRelationshipEdge(name: name, destinationKey: destinationKey, collection: OTRBuddy.collection(), nodeDeleteRules: YDB_NodeDeleteRules.DeleteSourceIfDestinationDeleted)]
        }
        return nil
        
    }
}

extension PushMessage: JSQMessageData {
    
}