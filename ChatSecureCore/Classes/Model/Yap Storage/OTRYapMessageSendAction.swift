//
//  OTRYapMessageSendAction.swift
//  ChatSecure
//
//  Created by David Chiles on 10/28/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import YapTaskQueue
import YapDatabase

extension OTRYapMessageSendAction: YapDatabaseRelationshipNode {
    
    // Relationship only really used to make sure tasks are deleted when messages are deleted
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        let edge = YapDatabaseRelationshipEdge(name: RelationshipEdgeName.messageActionEdgeName.name(), destinationKey: self.messageKey, collection: self.messageCollection, nodeDeleteRules: .deleteSourceIfDestinationDeleted)
        return [edge]
    }
    
}
