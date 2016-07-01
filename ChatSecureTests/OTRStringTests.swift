//
//  OTRStringTests.swift
//  ChatSecure
//
//  Created by David Chiles on 6/22/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import XCTest
@testable import ChatSecureCore

class OTRStringTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRemovingNonEnglishCharacter() {
        let str = "དབུ་མེདHelloདབུ་མེད123"
        let result = str.otr_stringByRemovingNonEnglishCharacters()
        XCTAssertEqual(result, "Hello123")
    }

}
