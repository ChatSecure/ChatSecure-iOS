//
//  ChatSecureUITests.swift
//  ChatSecureUITests
//
//  Created by David Chiles on 1/9/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import XCTest

class ChatSecureUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        setupSnapshot(app)

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateAccount() {
        let app = XCUIApplication()
        app.launchEnvironment["OTRLaunchMode"] = "ChatSecureUITests"
        app.launch()
        
        XCTAssertTrue(app.buttons["Skip"].exists, "Skip button exists")
        XCTAssertTrue(app.buttons["Create New Account"].exists, "Create new Account button exists")
        XCTAssertTrue(app.buttons["Add Existing Account"].exists, "Add existing account button exists")
        
        app.buttons["Create New Account"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.cells.containingType(.StaticText, identifier:"Nickname").childrenMatchingType(.TextField).element.typeText("Alice")
        app.toolbars.buttons["Done"].tap()
        tablesQuery.switches["Show Advanced Options"].tap()
        
        
        tablesQuery.switches["Enable Tor"].tap()
        
        snapshot("01CreateAccountScreen")
    }
    
    func testConversationList() {
        let app = XCUIApplication()
        app.launchEnvironment["OTRLaunchMode"] = "ChatSecureUITestsDemoData"
        app.launch()
        
        snapshot("02ConversationListScreen")
        XCUIApplication().tables["conversationTableView"].childrenMatchingType(.Any).elementBoundByIndex(0).tap()
        snapshot("03ChatScreen")
        XCUIApplication().navigationBars["Chats"].buttons["More Info"].tap()
        snapshot("04ProfileScreen")
        
//        app.navigationBars["Profile"].buttons["Done"].tap()
//        
//        let chatsNavigationBar = app.navigationBars["Chats"]
//        chatsNavigationBar.buttons["Chats"].tap()
//        chatsNavigationBar.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
//        app.tables["settingsTableView"].staticTexts["New Account"].tap()
//        app.buttons["Create New Account"].tap()
        
    }
    
}
