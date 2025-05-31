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

import Foundation
import XCTest

struct Wait {
    
    private static let sec30: TimeInterval = 30
    private static func actionFor(_ element: XCUIElement) -> String {
        "waiting for: \(element)"
    }
    
    @discardableResult
    static func inApp(
        _ app: XCUIApplication,
        forElement element: XCUIElement,
        timeout: TimeInterval = sec30
    ) -> XCUIApplication {
        XCTContext.runActivity(named: Self.actionFor(element)) { activity in
            XCTAssertTrue(element.waitForExistence(timeout: timeout), activity.name)
            return app
        }
    }
}
