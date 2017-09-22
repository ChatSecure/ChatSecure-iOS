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
    
    class func setupDatabaseWithName(_ name:String) -> OTRDatabaseManager {
        let datatabseManager = OTRTestDatabaseManager()
        datatabseManager.setDatabasePassphrase("password", remember: false, error: nil)
        datatabseManager.setupDatabase(withName: name, withMediaStorage: false)
        return datatabseManager
    }
}

extension FileManager {
    func clearDirectory(_ directory:String) {
        // Clear any Files in directy
        do {
            let contents = try self.contentsOfDirectory(atPath: directory)
            try contents.forEach { (path) in
                let fullPath = (directory as NSString).appendingPathComponent(path)
                try FileManager().removeItem(atPath: fullPath)
            }
        } catch let err {
            debugPrint("Error clearing test database \(err)")
        }
    }
}
