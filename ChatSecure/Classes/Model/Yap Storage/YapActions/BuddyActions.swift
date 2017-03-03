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
    case delete
}

open class BuddyAction: OTRYapDatabaseObject, YapActionable {
    
    open var action:BuddyActionType = .delete
    open var buddy:OTRBuddy?
    
    open func yapActionItems() -> [YapActionItem]? {
        
        guard let buddy = self.buddy else {
            return nil
        }
        
        return BuddyAction.actions(buddy, action: self.action)
    }
    
    open func hasYapActionItems() -> Bool {
        return true
    }
    
    open class func actions(_ buddy:OTRBuddy, action:BuddyActionType) -> [YapActionItem] {
        
        switch action {
        case .delete:
            let action = YapActionItem(identifier:"delete", date: nil, retryTimeout: 30, requiresInternet: true, block: { (collection, key, object, metadata) -> Void in
                
                guard let connection = OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection else {
                    return
                }
                
                var account:OTRAccount? = nil
                connection.read({ (transaction) -> Void in
                    account = OTRAccount.fetch(withUniqueID: buddy.accountUniqueId, transaction: transaction)
                })
                
                guard let acct = account else {
                    connection.readWrite({ (transaction) -> Void in
                        transaction.removeObject(forKey: key, inCollection: collection)
                    })
                    return
                }
                
                guard let proto = OTRProtocolManager.sharedInstance().protocol(for: acct) else {
                    connection.readWrite({ (transaction) -> Void in
                        transaction.removeObject(forKey: key, inCollection: collection)
                    })
                    return
                }
                if proto.connectionStatus() == .connected {
                    proto.removeBuddies([buddy])
                    connection.readWrite({ (transaction) -> Void in
                        transaction.removeObject(forKey: key, inCollection: collection)
                    })
                }
                
            })
            return [action]
        }

    }
}
