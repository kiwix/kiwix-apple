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

final class LoadingUI_iPhone_Test: XCTestCase {

    @MainActor
    func testLaunchingApp_onIPhone() throws {
        if !XCUIDevice.shared.orientation.isPortrait {
            XCUIDevice.shared.orientation = .portrait
        }
        
        let app = XCUIApplication()
        app.activate()
        let categoriesButton = app.buttons["Categories"]
        Wait.inApp(app, forElement: categoriesButton)
        XCTAssertTrue(categoriesButton.isSelected)
        
        app.buttons["New"].tap()
        app.buttons["Downloads"].tap()
        app.buttons["Opened"].tap()
        categoriesButton.tap()
        app.buttons["Done"].tap()
        
        XCTAssertFalse(app.buttons["Go Back"].isEnabled)
        XCTAssertFalse(app.buttons["Go Forward"].isEnabled)
        XCTAssertFalse(app.buttons["Share"].isEnabled)
        XCTAssertFalse(app.buttons["List"].isEnabled)
        XCTAssertFalse(app.buttons["Random Page"].isEnabled)
    }
}
