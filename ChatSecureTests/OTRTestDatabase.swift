//
//  OTRTestDatabase.swift
//  ChatSecure
//
//  Created by David Chiles on 10/7/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
@testable import ChatSecureCore

class OTRTestDatabaseManager:OTRDatabaseManager {
    override class func yapDatabaseDirectory() -> String {
        return NSTemporaryDirectory()
    }
    
    class func setupDatabaseWithName(name:String) -> OTRDatabaseManager {
        let datatabseManager = OTRTestDatabaseManager()
        datatabseManager.setDatabasePassphrase("password", remember: false, error: nil)
        datatabseManager.setupDatabaseWithName(name, withMediaStorage: false)
        return datatabseManager
    }
}

extension NSFileManager {
    func clearDirectory(directory:String) {
        // Clear any Files in directy
        do {
            let contents = try self.contentsOfDirectoryAtPath(directory)
            try contents.forEach { (path) in
                let fullPath = (directory as NSString).stringByAppendingPathComponent(path)
                try NSFileManager().removeItemAtPath(fullPath)
            }
        } catch {
            
        }
    }
}
