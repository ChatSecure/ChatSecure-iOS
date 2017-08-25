//
//  OTRXMPPRoom.swift
//  ChatSecure
//
//  Created by David Chiles on 10/7/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import UIKit
import YapDatabase.YapDatabaseRelationship

open class OTRXMPPRoom: OTRYapDatabaseObject {
    
    open var isArchived = false
    open var muteExpiration:Date?
    open var accountUniqueId:String?
    /** Your full JID for the room e.g. xmpp-development@conference.deusty.com/robbiehanson */
    open var ownJID:String?
    open var jid:String?
    open var joined = false
    open var messageText:String?
    open var lastRoomMessageId:String?
    open var subject:String?
    open var roomPassword:String?
    override open var uniqueId:String {
        get {
            if let account = self.accountUniqueId {
                if let jid = self.jid {
                    return OTRXMPPRoom.createUniqueId(account, jid: jid)
                }
            }
            return super.uniqueId
        }
    }
    
    open class func createUniqueId(_ accountId:String, jid:String) -> String {
        return accountId + jid
    }
}

extension OTRXMPPRoom:OTRThreadOwner {
    public func account(with transaction: YapDatabaseReadTransaction) -> OTRAccount? {
        return OTRAccount.fetchObject(withUniqueID: threadAccountIdentifier(), transaction: transaction)
    }
    
    public var isMuted: Bool {
        guard let expiration = muteExpiration else {
            return false
        }
        if expiration > Date() {
            return true
        }
        return false
    }
    
    public func threadName() -> String {
        return self.subject ?? self.jid ?? ""
    }
    
    public func threadIdentifier() -> String {
        return self.uniqueId
    }
    
    public func threadCollection() -> String {
        return OTRXMPPRoom.collection
    }
    
    public func threadAccountIdentifier() -> String {
        return self.accountUniqueId ?? ""
    }
    
    public func setCurrentMessageText(_ text: String?) {
        self.messageText = text
    }
    
    public func currentMessageText() -> String? {
        return self.messageText
    }
    
    public func avatarImage() -> UIImage {
        if let image = OTRImages.image(withIdentifier: self.uniqueId) {
            return image
        } else {
            // If not cached, generate a default image and store that.
            let seed = XMPPJID(string: self.jid).user ?? self.uniqueId
            if let image = OTRGroupAvatarGenerator.avatarImage(withSeed: seed, width: 100, height: 100) {
                OTRImages.setImage(image, forIdentifier: self.uniqueId)
                return image
            } else {
                return OTRImages.avatarImage(withUniqueIdentifier: self.uniqueId, avatarData: nil, displayName: nil, username: self.threadName())
            }
        }
    }
    
    public func currentStatus() -> OTRThreadStatus {
        switch self.joined {
        case true:
            return .available
        default:
            return .offline
        }
    }
    
    public func lastMessage(with transaction: YapDatabaseReadTransaction) -> OTRMessageProtocol? {
        
        guard let viewTransaction = transaction.ext(OTRFilteredChatDatabaseViewExtensionName) as? YapDatabaseViewTransaction else {
            return nil
        }
        let message = viewTransaction.lastObject(inGroup: self.threadIdentifier()) as? OTRMessageProtocol
        return message
    }
    
    public func numberOfUnreadMessages(with transaction: YapDatabaseReadTransaction) -> UInt {
        guard let indexTransaction = transaction.ext(OTRMessagesSecondaryIndex) as? YapDatabaseSecondaryIndexTransaction else {
            return 0
        }
        let queryString = "Where \(OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName) == ? AND \(OTRYapDatabaseUnreadMessageSecondaryIndexColumnName) == 0"
        let query = YapDatabaseQuery(string: queryString, parameters: [self.uniqueId])
        var count:UInt = 0
        let success = indexTransaction.getNumberOfRows(&count, matching: query)
        if (!success) {
            NSLog("Query error for OTRXMPPRoom numberOfUnreadMessagesWithTransaction")
        }
        return count
    }
    
    public func isGroupThread() -> Bool {
        return true
    }
}
