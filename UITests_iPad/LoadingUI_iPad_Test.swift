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
        
        if !XCUIDevice.shared.orientation.isLandscape {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        
        let app = XCUIApplication()
        app.launchArguments = ["ui_testing"]
        app.activate()
        
        app.buttons.matching(identifier: "ToggleSidebar").element.tap()
        
        let sidebar = app.collectionViews["sidebar_collection_view"]
        
        XCTAssert(sidebar.cells["New Tab"].isSelected)
        
        sidebar.cells["bookmarks"].tap()
        sidebar.cells["opened"].tap()
        sidebar.cells["categories"].tap()
        sidebar.cells["downloads"].tap()
        sidebar.cells["new"].tap()
        sidebar.cells["settings"].tap()
        sidebar.cells["donation"].tap()
    }
}
