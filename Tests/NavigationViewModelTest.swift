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

        let items = [1,2,3,4,5]
        XCTAssertEqual(items.closeBy { $0 == 1 }, 2)
        XCTAssertEqual(items.closeBy { $0 == 2 }, 1)
        XCTAssertEqual(items.closeBy { $0 == 3 }, 2)
        XCTAssertEqual(items.closeBy { $0 == 4 }, 3)
        XCTAssertEqual(items.closeBy { $0 == 5 }, 4)
        XCTAssertEqual(items.closeBy { $0 == 9 }, 5)
    }

}
