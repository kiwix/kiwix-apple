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

@MainActor
final class LoadingUI_iPad_Test: XCTestCase {

    func testLaunchingApp_on_iPad() throws {
        let app = XCUIApplication()
        app.activate()
        
        if !XCUIDevice.shared.orientation.isLandscape {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        
        // show sidebar
        app.navigationBars.buttons.firstMatch.tap()
        let _ = app.buttons["Wikipadia"].waitForExistence(timeout: 5)
        app.buttons["Wikipedia"].tap()
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
        // switch to a random page
        app.navigationBars.buttons["nav_random"].tap()
        
        // open another tab as well
        app.buttons["opened"].tap()
        app.buttons["Open: Apache Pig Docs"].tap()
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
        // show sidebar
        app.navigationBars.buttons.firstMatch.tap()
        let zimFileTab = app.buttons["Apache Pig Documentation"].firstMatch
        Wait.inApp(app, forElement: zimFileTab)
        XCTAssert(zimFileTab.isSelected)
        
        app.buttons["bookmarks"].tap()
        app.buttons["opened"].tap()
        app.buttons["categories"].tap()
        app.buttons["downloads"].tap()
        app.buttons["new"].tap()
        app.buttons["hotspot"].tap()
        app.buttons["settings"].tap()
        app.buttons["donation"].tap()
        app.buttons["close_payment_button"].tap()
    }
}
