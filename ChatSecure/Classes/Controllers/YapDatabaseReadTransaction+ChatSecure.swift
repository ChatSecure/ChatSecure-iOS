//
//  YapDatabaseReadTransaction+ChatSecure.swift
//  ChatSecure
//
//  Created by David Chiles on 10/27/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

extension YapDatabaseReadTransaction {
    
    public func enumerateMessages(id id:String, block:(message:OTRMesssageProtocol,stop:UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let secondaryIndexTransaction = self.ext(OTRYapDatabseMessageIdSecondaryIndexExtension) as? YapDatabaseSecondaryIndexTransaction else {
            return
        }
        
        let queryString = "Where \(OTRYapDatabseMessageIdSecondaryIndex) = ?"
        let query = YapDatabaseQuery(string: queryString, parameters: [id])
        
        secondaryIndexTransaction.enumerateKeysMatchingQuery(query) { (collection, key, stop) -> Void in
            if let message = self.objectForKey(key, inCollection: collection) as? OTRMesssageProtocol {
                block(message: message, stop: stop)
            }
        }
    }
}