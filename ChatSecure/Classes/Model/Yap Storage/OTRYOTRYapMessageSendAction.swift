//
//  OTRYOTRYapMessageSendAction.swift
//  ChatSecure
//
//  Created by David Chiles on 10/28/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import YapTaskQueue


extension OTRYapMessageSendAction:  YapTaskQueueAction {
    
    /// The yap key of this item
    public func yapKey() -> String {
        return self.uniqueId
    }
    
    /// The yap collection of this item
    public func yapCollection() -> String {
        return self.dynamicType.collection()
    }
    
    /// The queue that this item is in.
    public func queueName() -> String {
        let brokerName = YapDatabaseConstants.extensionName(.MessageQueueBrokerViewName)
        return "\(brokerName).\(self.buddyKey)"
    }
    
    /// How this item should be sorted compared to other items in it's queue
    public func sort(otherObject:YapTaskQueueAction) -> NSComparisonResult {
        guard let otherDate = (otherObject as? OTRYapMessageSendAction)?.date else {
            return .OrderedSame
        }
        return self.date.compare(otherDate)
    }
    
}
