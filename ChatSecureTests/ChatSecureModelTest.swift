//
//  ChatSecureModelTest.swift
//  ChatSecure
//
//  Created by David Chiles on 9/22/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import XCTest
import ChatSecure_Push_iOS
@testable import ChatSecureCore

class ChatSecureModelTest: XCTestCase {
    
    
    func testDeviceArchiving() {
        let date = Date()
        let id = "id"
        let reg = "reg"
        let accountID = "acctID"
        let device = Device(registrationID: reg, dateCreated: date, name: nil, deviceID: nil, id: id)
        let container = DeviceContainer()!
        container.pushDevice = device
        container.pushAccountKey = accountID
        
        let data = NSKeyedArchiver.archivedData(withRootObject: container)
        let newContainer = NSKeyedUnarchiver.unarchiveObject(with: data)!
        XCTAssertEqual(container.pushAccountKey, (newContainer as AnyObject).pushAccountKey)
        XCTAssertEqual(container.pushDevice?.registrationID, (newContainer as AnyObject).pushDevice!!.registrationID)
        XCTAssertEqual(container.pushDevice?.id, (newContainer as AnyObject).pushDevice!!.id)
    }
}

