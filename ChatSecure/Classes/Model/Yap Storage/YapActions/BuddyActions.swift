//
//  File.swift
//  ChatSecure
//
//  Created by David Chiles on 2/4/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase.YapDatabaseActionManager
import YapTaskQueue

@objc public enum BuddyActionType: Int {
    case delete
}

open class BuddyAction: OTRYapDatabaseObject, YapActionable {
    
    @objc open var action:BuddyActionType = .delete
    @objc open var buddy:OTRBuddy?
    
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
                
                guard let connection = OTRDatabaseManager.sharedInstance().writeConnection else {
                    return
                }
                
                var account:OTRAccount? = nil
                connection.read({ (transaction) -> Void in
                    account = OTRAccount.fetchObject(withUniqueID: buddy.accountUniqueId, transaction: transaction)
                })
                
                guard let acct = account else {
                    connection.readWrite({ (transaction) -> Void in
                        transaction.removeObject(forKey: key, inCollection: collection)
                    })
                    return
                }
                
                guard let proto = OTRProtocolManager.sharedInstance().protocol(for: acct) as? XMPPManager else {
                    connection.readWrite({ (transaction) -> Void in
                        transaction.removeObject(forKey: key, inCollection: collection)
                    })
                    return
                }
                if proto.loginStatus == .authenticated {
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

@objc open class OTRYapBuddyAction: OTRYapDatabaseObject, YapTaskQueueAction {
    @objc open var buddyKey:String = ""
    @objc open var date:Date = Date()

    override open var uniqueId: String {
        return buddyKey
    }

    override open class var collection: String {
        return OTRYapMessageSendAction.collection
    }
    
    /// The yap key of this item
    public func yapKey() -> String {
        return self.uniqueId
    }
    
    /// The queue that this item is in.
    public func queueName() -> String {
        let brokerName = YapDatabaseConstants.extensionName(.messageQueueBrokerViewName)
        return "\(brokerName).\(self.buddyKey)"
    }
    
    /// How this item should be sorted compared to other items in it's queue
    public func sort(_ otherObject:YapTaskQueueAction) -> ComparisonResult {
        guard let otherDate = (otherObject as? OTRYapBuddyAction)?.date else {
            return .orderedSame
        }
        return self.date.compare(otherDate)
    }
}

open class OTRYapAddBuddyAction :OTRYapBuddyAction, YapDatabaseRelationshipNode {
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        let edge = YapDatabaseRelationshipEdge(name: RelationshipEdgeName.buddyActionEdgeName.name(), destinationKey: self.buddyKey, collection: OTRBuddy.collection, nodeDeleteRules: .deleteSourceIfDestinationDeleted)
        return [edge]
    }
}

open class OTRYapRemoveBuddyAction :OTRYapBuddyAction {
    @objc open var accountKey:String?
    @objc open var buddyJid:String?
}
