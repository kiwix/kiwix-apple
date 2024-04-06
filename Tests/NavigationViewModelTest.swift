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

//
//  NavigationViewModelTest.swift
//  UnitTests

import XCTest
@testable import Kiwix

final class NavigationViewModelTest: XCTestCase {

    func testCloseByNavItem() throws {
        let noItems: [Int] = []
        XCTAssertNil(noItems.closeBy { $0 == 1 })

        let onlyItem = [1]
        XCTAssertNil(onlyItem.closeBy { $0 == 1 })
        XCTAssertEqual(onlyItem.closeBy { $0 == 9 }, 1)

        let items = [1, 2, 3, 4, 5]
        XCTAssertEqual(items.closeBy { $0 == 1 }, 2)
        XCTAssertEqual(items.closeBy { $0 == 2 }, 1)
        XCTAssertEqual(items.closeBy { $0 == 3 }, 2)
        XCTAssertEqual(items.closeBy { $0 == 4 }, 3)
        XCTAssertEqual(items.closeBy { $0 == 5 }, 4)
        XCTAssertEqual(items.closeBy { $0 == 9 }, 5)
    }

}
