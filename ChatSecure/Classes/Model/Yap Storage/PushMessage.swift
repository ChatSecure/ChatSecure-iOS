//
//  PushMessage.swift
//  ChatSecure
//
//  Created by David Chiles on 3/1/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

///A simple message object to mark when push or knock messages were sent off
@objc open class PushMessage: OTRYapDatabaseObject {
    @objc open var originId:String?
    @objc open var stanzaId:String?
    
    /// The buddy the knock was sent to
    @objc open var buddyKey:String?
    
    /// Any error from the ChatSecure-Push-Server
    @objc open var error:NSError?
    
    /// the date the push was sent, used for sorting
    @objc open var pushDate:Date = Date()
    
    @objc open var messageSecurityInfo: OTRMessageEncryptionInfo? = nil
    
    ///Send it to the same collection of other messages
    open class override var collection: String {
        return OTRBaseMessage.collection
    }
    
}

extension PushMessage: OTRMessageProtocol {
    
    public func buddy(with transaction: YapDatabaseReadTransaction) -> OTRXMPPBuddy? {
        return nil
    }
    
    public func duplicateMessage() -> OTRMessageProtocol {
        return PushMessage()
    }
    
    public var isMessageSent: Bool {
        return true
    }
    
    public var isMessageDelivered: Bool {
        return true
    }
    
    public var messageMediaItemKey: String? {
        get {
            return nil
        }
        set(messageMediaItemKey) {
            
        }
    }

    public var messageText: String? {
        get {
            return nil
        }
        set(messageText) {
            
        }
    }

    public var messageError: Error? {
        get {
            return self.error
        }
        set(messageError) {
            // let's do nothing here
        }
    }

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
    
    public var threadId: String {
        if let threadId = self.buddyKey {
            return threadId
        } else {
            fatalError("ThreadId should not be nil!")
        }
    }
    
    public var threadCollection: String {
        return OTRBuddy.collection
    }
    
    public var isMessageIncoming: Bool {
        return false
    }
    
    public var messageSecurity: OTRMessageTransportSecurity {
        get {
            return .plaintext
        }
        set {}
    }
    
    public var isMessageRead: Bool {
        return true
    }
    
    public var messageDate: Date {
        set {
            self.pushDate = newValue
        }
        get {
            return self.pushDate
        }
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
        OTRDatabaseManager.sharedInstance().uiConnection?.read { (transaction) -> Void in
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
