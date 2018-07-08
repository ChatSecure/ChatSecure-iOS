//
//  OTRTestDatabase.swift
//  ChatSecure
//
//  Created by David Chiles on 10/7/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
@testable import ChatSecureCore

extension OTRDatabaseManager {
    func setupTestDatabase(name: String) {
        try! setDatabasePassphrase("password", remember: false)
        let uuid = UUID().uuidString
        let tmpDir = NSTemporaryDirectory() as NSString
        let databaseDir = tmpDir.appendingPathComponent(uuid)
        setupDatabase(withName: name, directory: databaseDir, withMediaStorage: false)
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
