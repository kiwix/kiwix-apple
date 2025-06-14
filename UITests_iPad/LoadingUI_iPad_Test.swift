// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import XCTest

final class LoadingUI_iPad_Test: XCTestCase {

    @MainActor
    func testLaunchingApp_on_iPad() throws {
        let app = XCUIApplication()
        app.activate()
        
        if !XCUIDevice.shared.orientation.isLandscape {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        
        if !app.collectionViews["sidebar_collection_view"].exists {
            app.buttons.matching(identifier: "ToggleSidebar").element.tap()
        }
        
        let sidebar = app.collectionViews["sidebar_collection_view"]
        sidebar.cells["categories"].tap()
        app.buttons["Category, Wikipedia"].tap()
        app.buttons["Other"].tap()
        
        let zimMini = app.buttons["Apache Pig Docs"].firstMatch
        Wait.inApp(app, forElement: zimMini)
        zimMini.tap()
        
        let downloadButton = app.buttons["Download"].firstMatch
        Wait.inApp(app, forElement: downloadButton)
        downloadButton.tap()

        addUIInterruptionMonitor(withDescription: "\"Kiwix\" Would Like To Send You Notifications") { (alert) -> Bool in
            let alertButton = alert.buttons["Allow"]
            if alertButton.exists {
                alertButton.tap()
                return true
            }
            return false
        }
        let openMainPageButton = app.buttons["Open Main Page"]
        Wait.inApp(app, forElement: openMainPageButton)
        openMainPageButton.tap()
        usleep(1)
        
        // RESTART THE APP
        app.terminate()
        usleep(1)
        app.activate()
        
        testAfterRelaunch(app)
        
        app.terminate()
        
    }
    
    private func testAfterRelaunch(_ app: XCUIApplication) {
        let sidebar = app.collectionViews["sidebar_collection_view"]
        let zimFileTab = sidebar.cells["Apache Pig Documentation"].firstMatch
        Wait.inApp(app, forElement: zimFileTab)
        XCTAssert(sidebar.cells["Apache Pig Documentation"].firstMatch.isSelected)
        
        sidebar.cells["bookmarks"].tap()
        sidebar.cells["opened"].tap()
        sidebar.cells["categories"].tap()
        sidebar.cells["downloads"].tap()
        sidebar.cells["new"].tap()
        sidebar.cells["settings"].tap()
        sidebar.cells["donation"].tap()
        app.buttons["close_payment_button"].tap()
    }
}
