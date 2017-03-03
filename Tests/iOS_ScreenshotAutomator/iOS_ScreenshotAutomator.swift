//
//  iOS_ScreenshotAutomator.swift
//  iOS_ScreenshotAutomator
//
//  Created by Chris Li on 3/3/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import XCTest

class iOS_ScreenshotAutomator: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLibrary() {
        let app = XCUIApplication()
        let buttonInToolbar = app.toolbars.otherElements["Library"]
        if buttonInToolbar.exists {
            buttonInToolbar.tap()
        } else {
            app.navigationBars["Kiwix.Main"].otherElements["Library"].tap()
        }
        
        let refreshButton = app.collectionViews.buttons["Refresh"]
        if refreshButton.exists {
            refreshButton.tap()
            let alert = app.alerts["Filter Languages?"]
            let exists = NSPredicate(format: "exists == 1")
            expectation(for: exists, evaluatedWith: alert, handler: nil)
            waitForExpectations(timeout: 30, handler: nil)
            alert.buttons["Hide Other Languages"].tap()
            snapshot("03Library")
        } else {
            snapshot("03Library")
        }
    }
    
    func testWelcomePage() {
        snapshot("01Welcome")
    }
    

    
}
