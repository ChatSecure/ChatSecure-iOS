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
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: container, requiringSecureCoding: true)
            let newContainer = try NSKeyedUnarchiver.unarchivedObject(ofClass: DeviceContainer.self, from: data)
            XCTAssertEqual(container.pushAccountKey, newContainer?.pushAccountKey)
            XCTAssertEqual(container.pushDevice?.registrationID, newContainer?.pushDevice!.registrationID)
            XCTAssertEqual(container.pushDevice?.id, newContainer?.pushDevice!.id)
        } catch {
            XCTFail("Error \(error)")
        }
    }
}

