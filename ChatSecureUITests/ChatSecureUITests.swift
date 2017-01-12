//
//  ChatSecureUITests.swift
//  ChatSecureUITests
//
//  Created by David Chiles on 1/9/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import XCTest


// https://github.com/fastlane-old/snapshot/issues/321#issuecomment-159660882
func localizedString(key:String) -> String {
    let bundle = NSBundle(forClass: ChatSecureUITests.self)
    let locale = NSBundle.preferredLocalizationsFromArray(bundle.localizations, forPreferences: nil).first ?? "Base"
    let path =  bundle.pathForResource("Localizable", ofType: "strings", inDirectory: nil, forLocalization: locale)
    
    var foreignBundle = bundle
    if let path = path {
        let bundlePath = (path as NSString).stringByDeletingLastPathComponent
        foreignBundle = NSBundle(path: bundlePath)!
    }
    
    let result = NSLocalizedString(key, tableName: nil, bundle: foreignBundle, comment: "")
    return result
}
/*1 Gets correct bundle for the localization file, see here: http://stackoverflow.com/questions/33086266/cant-get-access-to-string-localizations-in-ui-test-xcode-7 */
/*2 Replace this with a class from your UI Tests */
/*3 Gets the localized string from the bundle */

func skipEnablePush(app:XCUIApplication) {
    if (app.buttons["EnablePushViewSkipButton"].exists) {
        app.buttons["EnablePushViewSkipButton"].tap()
    }
}

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
        skipEnablePush(app)
        
        XCTAssertTrue(app.buttons[localizedString("Skip")].exists, "Skip button exists")
        XCTAssertTrue(app.buttons[localizedString("Create New Account")].exists, "Create new Account button exists")
        XCTAssertTrue(app.buttons[localizedString("Add Existing Account")].exists, "Add existing account button exists")
        
        app.buttons[localizedString("Create New Account")].tap()
        
        let tablesQuery = app.tables
        tablesQuery.cells.containingType(.StaticText, identifier:localizedString("Nickname")).childrenMatchingType(.TextField).element.typeText("Alice")
        
        //This is the done button really

        switch UIDevice.currentDevice().userInterfaceIdiom  {
        case .Phone:
            XCUIApplication().toolbars.buttons.elementBoundByIndex(2).tap()
            break
        case .Pad:
            XCUIApplication().toolbars.buttons.elementBoundByIndex(3).tap()
            break
        default:
            break
        }
        
        tablesQuery.switches[localizedString("Show Advanced Options")].tap()
        
        
        tablesQuery.switches[localizedString("Enable Tor")].tap()
        
        snapshot("01CreateAccountScreen")
    }
    
    func testConversationList() {
        let app = XCUIApplication()
        app.launchEnvironment["OTRLaunchMode"] = "ChatSecureUITestsDemoData"
        app.launch()
        skipEnablePush(app)
        
        switch UIDevice.currentDevice().userInterfaceIdiom  {
        case .Phone:
            snapshot("02ConversationListScreen")
            break
        case .Pad:
            XCUIDevice.sharedDevice().orientation = .LandscapeLeft
            break
        default:
            break
        }
        sleep(2)
        skipEnablePush(app)
        XCUIApplication().tables["conversationTableView"].childrenMatchingType(.Any).elementBoundByIndex(0).tap()
        snapshot("03ChatScreen")
        XCUIApplication().buttons["profileButton"].tap()
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
