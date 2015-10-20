//
//  OTRXMPPRoom.swift
//  ChatSecure
//
//  Created by David Chiles on 10/7/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import UIKit
import YapDatabase

@objc public enum ThreadStatus:Int {
    case Available = 0
    case Away = 1
    case DoNotDisturb = 2
    case ExtendedAway = 3
    case Offline = 4
}

@objc public protocol OTRThreadOwner: NSObjectProtocol {
    
    func threadName() -> String
    func threadIdentifier() -> String
    func threadCollection() -> String
    func threadAccountIdentifier() -> String
    func setCurrentMessageText(text:String?)
    func currentMessageText() -> String?
    func lastMessageDate() -> NSDate?
    func avatarImage() -> UIImage
    func currentStatus() -> ThreadStatus
    func lastMessageWithTransaction(transaction:YapDatabaseReadTransaction) -> OTRMesssageProtocol?
}

public class OTRXMPPRoom: OTRYapDatabaseObject {
    
    public var accountUniqueId:String?
    public var ownJID:String?
    public var jid:String?
    public var joined = false
    public var messageText:String?
    public var lastRoomMessageDate:NSDate?
    override public var uniqueId:String {
        get {
            if let account = self.accountUniqueId {
                if let jid = self.jid {
                    return OTRXMPPRoom.createUniqueId(account, jid: jid)
                }
            }
            return super.uniqueId
        }
    }
    
    public class func createUniqueId(accountId:String, jid:String) -> String {
        return accountId + jid
    }
}

extension OTRXMPPRoom:OTRThreadOwner {
    public func threadName() -> String {
        return self.jid ?? ""
    }
    
    public func threadIdentifier() -> String {
        return self.uniqueId
    }
    
    public func threadCollection() -> String {
        return OTRXMPPRoom.collection()
    }
    
    public func threadAccountIdentifier() -> String {
        return self.accountUniqueId ?? ""
    }
    
    public func setCurrentMessageText(text: String?) {
        self.messageText = text
    }
    
    public func currentMessageText() -> String? {
        return self.messageText
    }
    
    public func lastMessageDate() -> NSDate? {
        return self.lastRoomMessageDate
    }
    
    public func avatarImage() -> UIImage {
        return OTRImages.avatarImageWithUniqueIdentifier(self.uniqueId, avatarData: nil, displayName: nil, username: self.jid)
    }
    
    public func currentStatus() -> ThreadStatus {
        switch self.joined {
        case true:
            return .Available
        default:
            return .Offline
        }
    }
    
    public func lastMessageWithTransaction(transaction: YapDatabaseReadTransaction) -> OTRMesssageProtocol? {
        //TODO
        return nil
    }
}
