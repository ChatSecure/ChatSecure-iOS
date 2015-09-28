//
//  PushSerializerTest.swift
//  ChatSecure
//
//  Created by David Chiles on 9/28/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import XCTest
import ChatSecure_Push_iOS
@testable import ChatSecureCore

class PushSerializerTest: XCTestCase {
    
    func testSerialization() {
        let array = [Token(tokenString: "token1", deviceID: nil),Token(tokenString: "token2", deviceID: nil),Token(tokenString: "token3", deviceID: nil)]
        let data = PushSerializer.serialize(array, APIEndpoint: "https://example.com/messages")
        XCTAssertNotNil(data,"No json data")
        do {
            let newArray = try PushDeserializer.deserializeToken(data!)
            XCTAssertEqual(array.count, newArray.count)
        } catch let error as NSError {
            XCTAssertNil(error)
        }
        
        
        
        
    }
}