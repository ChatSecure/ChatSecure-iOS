//
//  XMPPManager.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 11/27/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework

extension XMPPStream {
    /// Stream tags should be the OTRXMPPAccount uniqueId
    @objc public var accountId: String? {
        return tag as? String
    }
}

extension XMPPModule {
    /// yapKey for OTRAccount
    public var accountId: String? {
        return xmppStream?.accountId
    }
    
    public func account(with transaction: YapDatabaseReadTransaction) -> OTRXMPPAccount? {
        guard let accountId = self.accountId,
            let account = OTRXMPPAccount.fetchObject(withUniqueID: accountId, transaction: transaction) else {
                return nil
        }
        return account
    }
}


extension XMPPMessageArchiveManagement {
    @objc public func fetchHistory(archiveJID: XMPPJID? = nil, userJID: XMPPJID? = nil, since: Date? = nil) {
        var fields: [XMLElement] = []
        
        if let userJID = userJID {
            let with = XMPPMessageArchiveManagement.field(withVar: "with", type: nil, andValue: userJID.bare)
            fields.append(with)
        }
        
        if let since = since {
            let xmppDateString = (since as NSDate).xmppDateTimeString
            
            let start = XMPPMessageArchiveManagement.field(withVar: "start", type: nil, andValue: xmppDateString)
            fields.append(start)
        }
        retrieveMessageArchive(at: archiveJID ?? xmppStream?.myJID?.bareJID, withFields: fields, with: nil)
    }
    
    /** Fetches history for a thread after the most recent message */
    @objc public func fetchHistoryForThread(_ thread: OTRThreadOwner, transaction: YapDatabaseReadTransaction) {
        var archiveJID: XMPPJID? = nil
        var userJID: XMPPJID? = nil
        if let buddy = thread as? OTRXMPPBuddy,
            let buddyJID = buddy.bareJID,
            let account = account(with: transaction) {
            archiveJID = account.bareJID
            userJID = buddyJID
        } else if let room = thread as? OTRXMPPRoom {
            archiveJID = room.roomJID
        }
        let lastMessageDate = thread.lastMessage(with: transaction)?.messageDate
        fetchHistory(archiveJID: archiveJID, userJID: userJID, since: lastMessageDate)
    }
}

/// Formerly known in Obj-C as OTRXMPPManager
public extension XMPPManager {
    
    

}
