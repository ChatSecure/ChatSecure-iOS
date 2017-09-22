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
        let uuid = UUID().uuidString
        self.databaseManager = OTRTestDatabaseManager.setupDatabaseWithName(uuid)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testIncomingDirectMessage() {
        let incomingMessage = OTRIncomingMessage()!
        incomingMessage.buddyUniqueId = "6E7D268E-D63B-485C-99EA-7B8F78D779E2"
        internalTestDownloadsRelationship(incomingMessage: incomingMessage)
    }
    
    func testIncomingGroupMessage() {
        let incomingMessage = OTRXMPPRoomMessage()!
        incomingMessage.roomUniqueId = "7A3C3546-F19C-497B-970F-C3199F2C5E71"
        internalTestDownloadsRelationship(incomingMessage: incomingMessage)
    }
    
    private func internalTestDownloadsRelationship(incomingMessage: OTRMessageProtocol) {
        // this should be split into four messages
        var text = "i like cheese"
        let urls = ["https://cheese.com", "https://cheeze.biz/cheddar.jpg", "aesgcm://example.com/12345.png"]
        for url in urls {
            text = text + " " + url
        }
        incomingMessage.messageText = text
        writeConnection.readWrite { (transaction) in
            incomingMessage.save(with: transaction)
        }
        
        var hasDownloads = false
        readConnection.read({ (transaction) in
            hasDownloads = incomingMessage.hasExistingDownloads(with: transaction)
        })
        XCTAssertFalse(hasDownloads)
        
        let downloads = incomingMessage.downloads()
        XCTAssert(downloads.count > 0)
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
