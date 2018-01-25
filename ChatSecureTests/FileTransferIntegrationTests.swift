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
    
    var databaseManager: OTRDatabaseManager?
    var connection: YapDatabaseConnection!
    let account = OTRXMPPAccount(username: "test@test.com", accountType: .jabber)!
    let buddy = OTRXMPPBuddy()!
    let room = OTRXMPPRoom()!
    
    override func setUp() {
        super.setUp()
        DDLog.add(DDTTYLogger.sharedInstance)
        if let databaseDirectory = databaseManager?.databaseDirectory {
            FileManager.default.clearDirectory(databaseDirectory)
        }
        let uuid = UUID().uuidString
        self.databaseManager = OTRDatabaseManager()
        self.databaseManager?.setupTestDatabase(name: uuid)
        self.connection = self.databaseManager?.database!.newConnection()
        
        buddy.accountUniqueId = account.uniqueId
        room.accountUniqueId = account.uniqueId
        connection.readWrite { (t) in
            self.account.save(with: t)
            self.buddy.save(with: t)
            self.room.save(with: t)
        }
    }
    
    override func tearDown() {
        DDLog.removeAllLoggers()
        super.tearDown()
    }
    
    func testIncomingDirectMessageMultipleURLs() {
        let message = OTRIncomingMessage()!
        message.buddyUniqueId = buddy.uniqueId
        // this should be split into four messages
        let text = "i like cheese"
        let urls = ["https://cheese.com", "https://cheeze.biz/cheddar.jpg"]
        
        internalTestIncomingDownloadsRelationship(incomingMessage: message, text: text, urls: urls)
    }
    
    func testIncomingDirectMessageSingleURL() {
        let message = OTRIncomingMessage()!
        message.buddyUniqueId = buddy.uniqueId
        let text = ""
        let urls = ["https://example.com/12345.png"]
        internalTestIncomingDownloadsRelationship(incomingMessage: message, text: text, urls: urls)
    }
    
    func testIncomingDirectMessageSingleOMEMO() {
        let message = OTRIncomingMessage()!
        message.buddyUniqueId = buddy.uniqueId
        let text = ""
        let urls = ["aesgcm://example.com/12345.png"]
        internalTestIncomingDownloadsRelationship(incomingMessage: message, text: text, urls: urls, shouldDisplayMessage: false)
    }
    
    
    func testIncomingGroupMessage() {
        let incomingMessage = OTRXMPPRoomMessage()!
        incomingMessage.roomUniqueId = room.uniqueId
        // this should be split into four messages
        let text = "i like cheese"
        let urls = ["https://cheese.com", "https://cheeze.biz/cheddar.jpg"]
        internalTestIncomingDownloadsRelationship(incomingMessage: incomingMessage, text: text, urls: urls)
    }
    
    func testIncomingGroupMessageOMEMO() {
        let incomingMessage = OTRXMPPRoomMessage()!
        incomingMessage.roomUniqueId = room.uniqueId
        let text = ""
        let urls = ["aesgcm://example.com/12345.png"]
        internalTestIncomingDownloadsRelationship(incomingMessage: incomingMessage, text: text, urls: urls, shouldDisplayMessage: false)
    }
    
    /// NOTE: When we add MAM support, some internal logic in
    /// FileTransferManager and elsewhere may need to be changed
    /// because we will receive URLs/aesgcm links that we've sent on
    /// other clients that need to be downloaded.
    func testOutgoingDirectMessage() {
        let outgoingMessage = OTROutgoingMessage()!
        outgoingMessage.buddyUniqueId = buddy.uniqueId
        outgoingMessage.messageText = "https://test.com"
        internalTestOutgoingDownloadsRelationship(outgoingMessage: outgoingMessage)
    }
    
    func testOutgoingGroupMessage() {
        let outgoingMessage = OTRXMPPRoomMessage()!
        outgoingMessage.roomUniqueId = room.uniqueId
        outgoingMessage.state = .needsSending
        outgoingMessage.messageText = "https://test.com"
        internalTestOutgoingDownloadsRelationship(outgoingMessage: outgoingMessage)
    }
    
    // MARK: Internal Test Helpers
    
    /// `urls` will be appended to `text`
    private func internalTestIncomingDownloadsRelationship(incomingMessage: OTRMessageProtocol, text inText: String, urls: [String], shouldDisplayMessage: Bool = true) {
        connection.readWrite { (transaction) in
            incomingMessage.save(with: transaction)
        }
        var text = inText
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
            
            let shouldDisplay = FileTransferManager.shouldDisplayMessage(incomingMessage, transaction: transaction)
            XCTAssertEqual(shouldDisplay, shouldDisplayMessage)
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
    
    private func internalTestOutgoingDownloadsRelationship(outgoingMessage: OTRMessageProtocol) {
        connection.readWrite { (transaction) in
            outgoingMessage.save(with: transaction)
        }
        var hasDownloads = false
        connection.read { (transaction) in
            hasDownloads = outgoingMessage.hasExistingDownloads(with: transaction)
            let shouldDisplayMessage = FileTransferManager.shouldDisplayMessage(outgoingMessage, transaction: transaction)
            XCTAssertTrue(shouldDisplayMessage)
        }
        XCTAssertFalse(hasDownloads)
        
        let downloads = outgoingMessage.downloads()
        XCTAssert(downloads.count == 0)
    }
    
    
}


