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
    open class override var collection: String {
        return OTRBaseMessage.collection
    }
    
}

extension PushMessage: OTRMessageProtocol {
    public func downloads() -> [OTRDownloadMessage] {
        return []
    }
    
    public func existingDownloads(with transaction: YapDatabaseReadTransaction) -> [OTRDownloadMessage] {
        return []
    }
    
    public func hasExistingDownloads(with transaction: YapDatabaseReadTransaction) -> Bool {
        return false
    }
    
    public var messageKey: String {
        return self.uniqueId
    }
    
    public var messageCollection: String {
        return OTRBaseMessage.collection
    }
    
    public var threadId: String? {
        return self.buddyKey
    }
    
    public var threadCollection: String {
        return OTRBuddy.collection
    }
    
    public var isMessageIncoming: Bool {
        return false
    }
    
    public var messageMediaItemKey: String? {
        return nil
    }
    
    public var messageError: Error? {
        return self.error
    }
    
    public var messageSecurity: OTRMessageTransportSecurity {
        return .plaintext
    }
    
    public var isMessageRead: Bool {
        return true
    }
    
    public var messageDate: Date {
        return self.pushDate
    }
    
    public var messageText: String? {
        return nil
    }
    
    public var remoteMessageId: String? {
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
            return [YapDatabaseRelationshipEdge(name: name, destinationKey: destinationKey, collection: OTRBuddy.collection, nodeDeleteRules: YDB_NodeDeleteRules.deleteSourceIfDestinationDeleted)]
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
    public func text() -> String {
        return self.messageText ?? ""
    }
    
    public func date() -> Date {
        return self.messageDate
    }

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
