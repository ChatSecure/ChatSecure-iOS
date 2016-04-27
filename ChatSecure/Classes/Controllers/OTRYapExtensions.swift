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

public class OTRYapExtensions:NSObject {
    
    /// Creates a FTS extension on the buddy's username and display name
    public class func buddyFTS() -> YapDatabaseFullTextSearch {
        
        let usernameColumnName = BuddyFTSColumnName.Username.name()
        let displayNameColumnName = BuddyFTSColumnName.DisplayName.name()
        
        let searchHandler = YapDatabaseFullTextSearchHandler.withObjectBlock { (dict, collection, key, object) in
            guard let buddy = object as? OTRBuddy else {
                return
            }
            
            if let username = buddy.username {
                dict.setObject(username, forKey: usernameColumnName)
            }
            
            if let displayNme = buddy.displayName {
                dict.setObject(displayNme, forKey: displayNameColumnName)
            }
            
        }
        
        let columnNames = [usernameColumnName,displayNameColumnName]
        
        return YapDatabaseFullTextSearch(columnNames: columnNames, handler: searchHandler)
        
    }
}