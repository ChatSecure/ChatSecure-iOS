//
//  FileTransferIntegrationTests.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 5/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import XCTest
@testable import ChatSecureCore

class FileTransferIntegrationTests: XCTestCase {
    
    var databaseManager: OTRDatabaseManager!
    var readConnection: YapDatabaseConnection {
        return databaseManager.readOnlyDatabaseConnection!
    }
    var writeConnection: YapDatabaseConnection {
        return databaseManager.readWriteDatabaseConnection!
    }
    
    override func setUp() {
        super.setUp()
        FileManager.default.clearDirectory(OTRTestDatabaseManager.yapDatabaseDirectory())
        self.databaseManager = OTRTestDatabaseManager.setupDatabaseWithName("Test")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDownloadsRelationship() {
        
        let incomingMessage = OTRIncomingMessage(uniqueId: NSUUID().uuidString)
        // this should be split into four messages
        var text = "i like cheese"
        let urls = ["https://cheese.com", "https://cheeze.biz/cheddar.jpg", "aesgcm://example.com/12345.png"]
        for url in urls {
            text = text + " " + url
        }
        incomingMessage.text = text
        writeConnection.readWrite { (transaction) in
            incomingMessage.save(with: transaction)
        }
        
        var hasDownloads = false
        readConnection.read({ (transaction) in
            hasDownloads = incomingMessage.hasExistingDownloads(with: transaction)
        })
        XCTAssertFalse(hasDownloads)
        
        let downloads = incomingMessage.downloads()
        writeConnection.readWrite { (transaction) in
            for download in downloads {
                download.save(with: transaction)
            }
        }
        var savedDownloads: [OTRDownloadMessage] = []
        readConnection.read({ (transaction) in
            hasDownloads = incomingMessage.hasExistingDownloads(with: transaction)
            savedDownloads = incomingMessage.existingDownloads(with: transaction)
        })
        XCTAssertTrue(hasDownloads)
        XCTAssertEqual(urls.count, savedDownloads.count)
    }
    
    
}
