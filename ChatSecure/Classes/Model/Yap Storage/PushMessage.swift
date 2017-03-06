//
//  PushMessage.swift
//  ChatSecure
//
//  Created by David Chiles on 3/1/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

///A simple message object to mark when push or knock messages were sent off
open class PushMessage: OTRYapDatabaseObject {
    
    /// The buddy the knock was sent to
    open var buddyKey:String?
    
    /// Any error from the ChatSecure-Push-Server
    open var error:NSError?
    
    /// the date the push was sent, used for sorting
    open var pushDate:Date = Date()
    
    ///Send it to the same collection of other messages
    open class override func collection() -> String {
        return OTRBaseMessage.collection()
    }
    
}

extension PushMessage: OTRMessageProtocol {
    public func messageKey() -> String {
        return self.uniqueId
    }
    
    public func messageCollection() -> String {
        return OTRBaseMessage.collection()
    }
    
    public func threadId() -> String? {
        return self.buddyKey
    }
    
    public func messageIncoming() -> Bool {
        return false
    }
    
    public func messageMediaItemKey() -> String? {
        return nil
    }
    
    public func messageError() -> Error? {
        return self.error
    }
    
    public func messageSecurity() -> OTRMessageTransportSecurity {
        return .plaintext
    }
    
    public func messageRead() -> Bool {
        return true
    }
    
    public func date() -> Date {
        return self.pushDate
    }
    
    public func text() -> String? {
        return nil
    }
    
    public func remoteMessageId() -> String? {
        return nil
    }
    
    public func threadOwner(with transaction: YapDatabaseReadTransaction) -> OTRThreadOwner? {
        guard let key = self.buddyKey else {
            return nil
        }
        return OTRBuddy.fetchObject(withUniqueID: key, transaction: transaction)
    }
}

extension PushMessage: YapDatabaseRelationshipNode {
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        
        if let destinationKey = self.buddyKey {
            let name = "buddy"
            return [YapDatabaseRelationshipEdge(name: name, destinationKey: destinationKey, collection: OTRBuddy.collection(), nodeDeleteRules: YDB_NodeDeleteRules.deleteSourceIfDestinationDeleted)]
        }
        return nil
        
    }
}

extension PushMessage {
    func account() -> OTRAccount? {
        var account:OTRAccount? = nil
        OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection?.read { (transaction) -> Void in
            if let buddyKey = self.buddyKey {
                if let buddy = OTRBuddy.fetchObject(withUniqueID: buddyKey, transaction: transaction) {
                    account = buddy.account(with: transaction)
                }
            }
        }
        return account
    }
}

extension PushMessage: JSQMessageData {
    public func senderId() -> String! {
        let account = self.account()
        return account?.uniqueId ?? ""
    }
    
    public func senderDisplayName() -> String! {
        let account = self.account()
        let displayName = (account?.displayName ?? account?.username) ?? ""
        return displayName
    }
    
    public func messageHash() -> UInt {
        return UInt(abs(self.uniqueId.hash))
    }
    
    public func isMediaMessage() -> Bool {
        return false
    }
}
