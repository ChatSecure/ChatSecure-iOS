//
//  XMPPManager.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 11/27/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework

extension XMPPMessageArchiveManagement {
    public func fetchHistory(archiveJID: XMPPJID? = nil, userJID: XMPPJID? = nil, since: Date? = nil) {
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
        retrieveMessageArchive(at: archiveJID, withFields: fields, with: nil)
    }
}

/// Formerly known in Obj-C as OTRXMPPManager
public extension XMPPManager {
    
    
    /** Fetches history for a thread after the most recent message */
    @objc public func fetchHistoryForThread(_ thread: OTRThreadOwner, transaction: YapDatabaseReadTransaction) {
        var archiveJID: XMPPJID? = nil
        var userJID: XMPPJID? = nil
        if let buddy = thread as? OTRXMPPBuddy,
            let buddyJID = buddy.bareJID {
            archiveJID = account.bareJID
            userJID = buddyJID
        } else if let room = thread as? OTRXMPPRoom {
            archiveJID = room.roomJID
        }
        let lastMessageDate = thread.lastMessage(with: transaction)?.messageDate
        messageStorage.archiving.fetchHistory(archiveJID: archiveJID, userJID: userJID, since: lastMessageDate)
    }
}
