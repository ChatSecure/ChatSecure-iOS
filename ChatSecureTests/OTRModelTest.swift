//
//  OTRModelTest.swift
//  ChatSecure
//
//  Created by David Chiles on 12/8/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import XCTest
@testable import ChatSecureCore

class OTRModelTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDuplicateMessage() {
        let text = "text"
        let buddyUniqueId = "buddyUniqueId"
        let securityInfo = OTRMessageEncryptionInfo.init(plaintext:())
        
        let outgoingMessage = OTROutgoingMessage()!
        outgoingMessage.text = text
        outgoingMessage.buddyUniqueId = buddyUniqueId
        outgoingMessage.messageSecurityInfo = securityInfo
        let newMessage = outgoingMessage.duplicateMessage()
        XCTAssertNotNil(newMessage)
        XCTAssertEqual(newMessage.messageText, text)
        XCTAssertEqual(newMessage.threadId, buddyUniqueId)
        XCTAssertEqual(newMessage.messageSecurity, securityInfo.messageSecurity)
    }
}
