//
//  AESGCMTests.swift
//  ChatSecureTests
//
//  Created by Chris Ballinger on 2/16/20.
//  Copyright © 2020 Chris Ballinger. All rights reserved.
//

import XCTest
@testable import ChatSecureCore

class AESGCMTests: XCTestCase {
    func random(length: Int) -> Data {
        let bytes = (0 ..< length).map { _ in UInt8.random(in: .min ... .max) }
        XCTAssertEqual(bytes.count, length)
        return Data(bytes)
    }
    
    func testLegacy16ByteIV() throws {
        let messageData = "Test".data(using: .utf8)!
        let key = random(length: 16)
        let iv = random(length: 16)
        let encryptedData = try XCTUnwrap(try OTRSignalEncryptionHelper.encryptData(messageData, key: key, iv: iv))
        let decryptedData = try XCTUnwrap(try OTRSignalEncryptionHelper.decryptData(encryptedData.data, key: key, iv: iv, authTag: encryptedData.authTag))
        XCTAssertEqual(messageData, decryptedData)
    }
    
    func test12ByteIV() throws {
        let messageData = "Test".data(using: .utf8)!
        let key = random(length: 16)
        let iv = random(length: 12)
        let encryptedData = try XCTUnwrap(try OTRSignalEncryptionHelper.encryptData(messageData, key: key, iv: iv))
        let decryptedData = try XCTUnwrap(try OTRSignalEncryptionHelper.decryptData(encryptedData.data, key: key, iv: iv, authTag: encryptedData.authTag))
        XCTAssertEqual(messageData, decryptedData)
    }
}
