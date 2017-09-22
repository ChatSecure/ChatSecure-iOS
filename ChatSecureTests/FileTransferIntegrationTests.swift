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
    var connection: YapDatabaseConnection!
    
    override func setUp() {
        super.setUp()
        FileManager.default.clearDirectory(OTRTestDatabaseManager.yapDatabaseDirectory())
        let uuid = UUID().uuidString
        self.databaseManager = OTRTestDatabaseManager.setupDatabaseWithName(uuid)
        self.connection = self.databaseManager.readWriteDatabaseConnection!
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
        connection.readWrite { (transaction) in
            debugPrint("Saving message \(incomingMessage.messageCollection) \(incomingMessage.messageKey)")
            incomingMessage.save(with: transaction)
            let refetch = incomingMessage.refetch(with: transaction)
            XCTAssertNotNil(refetch)
        }
        
        var hasDownloads = false
        connection.read({ (transaction) in
            let refetch = incomingMessage.refetch(with: transaction)
            XCTAssertNotNil(refetch)
            hasDownloads = incomingMessage.hasExistingDownloads(with: transaction)
        })
        XCTAssertFalse(hasDownloads)
        
        let downloads = incomingMessage.downloads()
        XCTAssert(downloads.count > 0)
        connection.readWrite { (transaction) in
            for download in downloads {
                debugPrint("Saving download \(download.messageCollection) \(download.messageKey)")
                download.save(with: transaction)
                let refetch = download.refetch(with: transaction)
                XCTAssertNotNil(refetch)
                debugPrint("Attempting parent fetch \(download.parentObjectCollection!) \(download.parentObjectKey!)")

                let parentObject = download.parentObject(with: transaction)
                let parentMessage = download.parentMessage(with: transaction)
                let parentRefetch = incomingMessage.refetch(with: transaction)
                XCTAssertNotNil(parentRefetch)
                XCTAssertNotNil(parentObject)
                XCTAssertNotNil(parentMessage)
            }
        }
        var savedDownloads: [OTRDownloadMessage] = []
        connection.read({ (transaction) in
            for download in downloads {
                let refetch = download.refetch(with: transaction)
                XCTAssertNotNil(refetch)
            }
            hasDownloads = incomingMessage.hasExistingDownloads(with: transaction)
            savedDownloads = incomingMessage.existingDownloads(with: transaction)
        })
        XCTAssertTrue(hasDownloads)
        XCTAssertEqual(urls.count, savedDownloads.count)
    }
    
    
}
