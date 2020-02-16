//
//  OTRYapExtensions.swift
//  ChatSecure
//
//  Created by David Chiles on 4/22/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase.YapDatabaseFullTextSearch
import YapDatabase.YapDatabaseSearchResultsView

open class OTRYapExtensions:NSObject {
    
    /// Creates a FTS extension on the buddy's username and display name
    @objc open class func buddyFTS() -> YapDatabaseFullTextSearch {
        
        let usernameColumnName = BuddyFTSColumnName.username.name()
        let displayNameColumnName = BuddyFTSColumnName.displayName.name()
        
        let searchHandler = YapDatabaseFullTextSearchHandler.withObjectBlock { (transaction, dict, collection, key, object) in
            guard let buddy = object as? OTRBuddy else {
                return
            }
            
            dict.setObject(buddy.username, forKey: usernameColumnName as NSString)
            
            dict.setObject(buddy.displayName, forKey: displayNameColumnName as NSString)
            
        }
        
        let columnNames = [usernameColumnName,displayNameColumnName]
        
        return YapDatabaseFullTextSearch(columnNames: columnNames, handler: searchHandler)
        
    }
}
