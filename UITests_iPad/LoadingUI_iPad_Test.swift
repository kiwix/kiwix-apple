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

// swiftlint:disable:next type_name
@MainActor final class LoadingUI_iPad_Test: XCTestCase {

    func testLaunchingApp_on_iPad() throws {
        let app = XCUIApplication()
        app.activate()
        
        if !XCUIDevice.shared.orientation.isLandscape {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        
        // show sidebar
        app.navigationBars.buttons.firstMatch.tap()
        
        // select categories (might not be selected)
        app.buttons["categories"].tap()
        
        let searchField = app.navigationBars.searchFields.firstMatch
        _ = searchField.waitForExistence(timeout: 60)
        searchField.tap()
        searchField.typeText("Alpine")
        
        let zimMini = app.buttons["Alpine Linux Wiki"].firstMatch
        Wait.inApp(app, forElement: zimMini, timeout: 120)
        zimMini.tap()
        
        let downloadButton = app.buttons["Download"].firstMatch
        Wait.inApp(app, forElement: downloadButton, timeout: 120)

        addUIInterruptionMonitor(withDescription: "\"Kiwix\" Would Like To Send You Notifications") { (alert) -> Bool in
            let alertButton = alert.buttons["Allow"]
            if alertButton.exists {
                alertButton.tap()
                return true
            }
            return false
        }
        downloadButton.tap()
        usleep(100_000)
        let openMainPageButton = app.buttons["Open Main Page"]
        Wait.inApp(app, forElement: openMainPageButton, timeout: 240)
        openMainPageButton.tap()

        app.webViews.firstMatch.tap()
        
        switchToAnotherPage(app)
        
        // open another tab as well
        app.buttons["opened"].tap()
        app.buttons["Open: Alpine Linux Wiki"].tap()
        Wait.inApp(app, forElement: openMainPageButton)
        openMainPageButton.tap()
        usleep(500_000)
        // RESTART THE APP
        app.terminate()
        app.activate()
        
        if !XCUIDevice.shared.orientation.isLandscape {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        usleep(750_000)
        testAfterRelaunch(app)
        testForegroundViaFinderDeeplink(app)
        testLaunchViaDeeplink(app)
    }
    
    private func testAfterRelaunch(_ app: XCUIApplication) {
        let zimFileTab = app.collectionViews["Sidebar"].cells.buttons["Main Page"].firstMatch
        Wait.inApp(app, forElement: zimFileTab)
        usleep(900_000)
        XCTAssert(zimFileTab.isSelected)
        switchToAnotherPage(app)
        
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
    
    private func testForegroundViaFinderDeeplink(_ app: XCUIApplication) {
        XCUIDevice.shared.press(.home)
        XCUIDevice.shared.press(.home)

        let documentsApp = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        documentsApp.activate()
        documentsApp.collectionViews["Browse View"].firstMatch.cells["On My iPad"].firstMatch.tap()
        documentsApp.cells["Kiwix, Container"].firstMatch.tap()
        // find the zim file, something like: alpinelinux_en_all_maxi_2026-07.zim
        let alpineFile = documentsApp.cells.matching(
            NSPredicate(format: "identifier MATCHES[c] %@",
                        String(format: ".*\\b%@.*", "alpinelinux"))
        ).firstMatch
        
        alpineFile.tap()
        usleep(500_000)
        let zimFileTab = app.collectionViews["Sidebar"].cells.buttons["Main Page"].firstMatch
        Wait.inApp(app, forElement: zimFileTab)
        XCTAssert(zimFileTab.isSelected)
        switchToAnotherPage(app)
    }
    
    private func testLaunchViaDeeplink(_ app: XCUIApplication) {
        
        app.terminate()
        XCUIDevice.shared.press(.home)
        usleep(50_000)
        
        let documentsApp = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        documentsApp.activate()
        documentsApp.collectionViews["Browse View"].firstMatch.cells["On My iPad"].firstMatch.tap()
        documentsApp.cells["Kiwix, Container"].firstMatch.tap()
        // find the zim file, something like: alpinelinux_en_all_maxi_2026-07.zim
        let alpineFile = documentsApp.cells.matching(
            NSPredicate(format: "identifier MATCHES[c] %@",
                        String(format: ".*\\b%@.*", "alpinelinux"))
        ).firstMatch
        
        alpineFile.tap()
        usleep(500_000)
        let zimFileTab = app.collectionViews["Sidebar"].cells.buttons["Main Page"].firstMatch
        Wait.inApp(app, forElement: zimFileTab)
        usleep(500_000)
        usleep(500_000)
        usleep(500_000)
        XCTAssert(zimFileTab.isSelected)
        usleep(50_000)
        switchToAnotherPage(app)
    }
    
    private func switchToAnotherPage(_ app: XCUIApplication) {
        let installLink = app.links["Installation"].firstMatch
        Wait.inApp(app, forElement: installLink)
        installLink.tap()
        usleep(1_000)
    }
}
