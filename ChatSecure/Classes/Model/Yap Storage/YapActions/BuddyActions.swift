//
//  File.swift
//  ChatSecure
//
//  Created by David Chiles on 2/4/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase.YapDatabaseActionManager

@objc public enum BuddyActionType: Int {
    case Delete
}

public class BuddyAction: OTRYapDatabaseObject, YapActionable {
    
    public var action:BuddyActionType = .Delete
    public var buddy:OTRBuddy?
    
    public func yapActionItems() -> [YapActionItem]? {
        
        guard let buddy = self.buddy else {
            return nil
        }
        
        return BuddyAction.actions(buddy, action: self.action)
    }
    
    public func hasYapActionItems() -> Bool {
        return true
    }
    
    public class func actions(buddy:OTRBuddy, action:BuddyActionType) -> [YapActionItem] {
        
        switch action {
        case .Delete:
            let action = YapActionItem(identifier:"delete", date: nil, retryTimeout: 30, requiresInternet: true, block: { (collection, key, object, metadata) -> Void in
                
                let connection = OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection
                
                var account:OTRAccount? = nil
                connection.readWithBlock({ (transaction) -> Void in
                    account = OTRAccount.fetchObjectWithUniqueID(buddy.accountUniqueId, transaction: transaction)
                })
                
                guard let acct = account else {
                    return
                }
                
                let proto = OTRProtocolManager.sharedInstance().protocolForAccount(acct)
                if proto.connectionStatus() == .Connected {
                    proto.removeBuddies([buddy])
                    connection.readWriteWithBlock({ (transaction) -> Void in
                        transaction.removeObjectForKey(key, inCollection: collection)
                    })
                }
                
            })
            return [action]
        }

    }
}
