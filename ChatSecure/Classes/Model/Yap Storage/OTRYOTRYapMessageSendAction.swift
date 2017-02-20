//
//  OTRYOTRYapMessageSendAction.swift
//  ChatSecure
//
//  Created by David Chiles on 10/28/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import YapTaskQueue
import YapDatabase


extension OTRYapMessageSendAction:  YapTaskQueueAction {
    
    /// The yap key of this item
    public func yapKey() -> String {
        return self.uniqueId
    }
    
    /// The yap collection of this item
    public func yapCollection() -> String {
        return type(of: self).collection()
    }
    
    /// The queue that this item is in.
    public func queueName() -> String {
        let brokerName = YapDatabaseConstants.extensionName(.messageQueueBrokerViewName)
        return "\(brokerName).\(self.buddyKey)"
    }
    
    /// How this item should be sorted compared to other items in it's queue
    public func sort(_ otherObject:YapTaskQueueAction) -> ComparisonResult {
        guard let otherDate = (otherObject as? OTRYapMessageSendAction)?.date else {
            return .orderedSame
        }
        return self.date.compare(otherDate)
    }
    
}

extension OTRYapMessageSendAction: YapDatabaseRelationshipNode {
    
    // Relationship only really used to make sure tasks are deleted when messages are deleted
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        let edge = YapDatabaseRelationshipEdge(name: RelationshipEdgeName.messageActionEdgeName.name(), destinationKey: self.messageKey, collection: self.messageCollection, nodeDeleteRules: .deleteSourceIfDestinationDeleted)
        return [edge]
    }
    
}
