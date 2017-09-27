//
//  FileTransferIntegrationTests.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 5/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import XCTest
import CocoaLumberjack
@testable import ChatSecureCore

class FileTransferIntegrationTests: XCTestCase {
    
    var databaseManager: OTRDatabaseManager!
    var connection: YapDatabaseConnection!
    
    override func setUp() {
        super.setUp()
        DDLog.add(DDTTYLogger.sharedInstance)
        FileManager.default.clearDirectory(OTRTestDatabaseManager.yapDatabaseDirectory())
        let uuid = UUID().uuidString
        self.databaseManager = OTRTestDatabaseManager.setupDatabaseWithName(uuid)
        self.connection = self.databaseManager.database!.newConnection()
    }
    
    override func tearDown() {
        DDLog.removeAllLoggers()
        super.tearDown()
    }
    
    func testIncomingDirectMessage() {
        let account = OTRXMPPAccount(username: "test@test.com", accountType: .jabber)!
        let buddy = OTRXMPPBuddy()!
        buddy.accountUniqueId = account.uniqueId
        let incomingMessage = OTRIncomingMessage()!
        incomingMessage.buddyUniqueId = buddy.uniqueId
        connection.readWrite { (transaction) in
            account.save(with: transaction)
            buddy.save(with: transaction)
            incomingMessage.save(with: transaction)
        }
        internalTestDownloadsRelationship(incomingMessage: incomingMessage)
    }
    
    func testIncomingGroupMessage() {
        let account = OTRXMPPAccount(username: "test@test.com", accountType: .jabber)!
        let room = OTRXMPPRoom()!
        room.accountUniqueId = account.uniqueId
        let incomingMessage = OTRXMPPRoomMessage()!
        incomingMessage.roomUniqueId = room.uniqueId
        connection.readWrite { (transaction) in
            account.save(with: transaction)
            room.save(with: transaction)
            incomingMessage.save(with: transaction)
        }
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
            DDLogInfo("Saving message \(incomingMessage.messageCollection) \(incomingMessage.messageKey)")
            incomingMessage.save(with: transaction)
            DDLogInfo("Refetching \(incomingMessage.messageCollection) \(incomingMessage.messageKey)")
            let refetch = incomingMessage.refetch(with: transaction)
            XCTAssertNotNil(refetch)
        }
        
        var hasDownloads = false
        connection.read { (transaction) in
            DDLogInfo("Refetching \(incomingMessage.messageCollection) \(incomingMessage.messageKey)")
            let refetch = incomingMessage.refetch(with: transaction)
            XCTAssertNotNil(refetch)
            hasDownloads = incomingMessage.hasExistingDownloads(with: transaction)
        }
        XCTAssertFalse(hasDownloads)
        
        let downloads = incomingMessage.downloads()
        XCTAssert(downloads.count > 0)
        connection.readWrite { (transaction) in
            for download in downloads {
                DDLogInfo("Saving download \(download.messageCollection) \(download.messageKey)")
                download.save(with: transaction)
                let refetch = download.refetch(with: transaction)
                XCTAssertNotNil(refetch)
                DDLogInfo("Attempting parent fetch \(download.parentObjectCollection!) \(download.parentObjectKey!)")

                let parentObject = download.parentObject(with: transaction)
                let parentMessage = download.parentMessage(with: transaction)
                let parentRefetch = incomingMessage.refetch(with: transaction)
                XCTAssertNotNil(parentRefetch)
                XCTAssertNotNil(parentObject)
                XCTAssertNotNil(parentMessage)
            }
        }
        var savedDownloads: [OTRDownloadMessage] = []
        connection.read { (transaction) in
            for download in downloads {
                let refetch = download.refetch(with: transaction)
                XCTAssertNotNil(refetch)
            }
            hasDownloads = incomingMessage.hasExistingDownloads(with: transaction)
            savedDownloads = incomingMessage.existingDownloads(with: transaction)
        }
        XCTAssertTrue(hasDownloads)
        XCTAssertEqual(urls.count, savedDownloads.count)
    }
    
    
}
