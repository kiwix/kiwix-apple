//
//  KiwixUITests.swift
//  KiwixUITests
//
//  Created by Chris on 12/11/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import XCTest

class SnapshotAutomation: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        XCUIApplication().launch()

        let app = XCUIApplication()
        if app.alerts.count > 0 {
            app.alerts["Welcome to Kiwix"].collectionViews.buttons["Dismiss"].tap()
        }
        
        snapshot("01WelcomeScreen")
        
        if app.toolbars.buttons["Library"].exists {
            // iPhone
            app.toolbars.buttons["Library"].tap()
            sleep(4)
            if app.alerts.count > 0 {
                app.alerts["Only Show Preferred Language?"].collectionViews.buttons["OK"].tap()
            }
            snapshot("02LibraryScreen")
        } else {
            // iPad
            app.navigationBars["Kiwix.MainVC"].childrenMatchingType(.Button).elementBoundByIndex(4).tap()
            sleep(4)
            if app.alerts.count > 0 {
                app.alerts["Only Show Preferred Language?"].collectionViews.buttons["OK"].tap()
            }
            snapshot("02LibraryScreen")
        }
        
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
