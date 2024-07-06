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
@testable import Kiwix

final class BackListURLsTests: XCTestCase {

    func testEmptyLists() {
        let canGoBack = BackListURLs.filteredCanGoBack(
            backURLs: [],
            current: URL(string: "https://kiwix.org")!,
            skipList: [:]
        )
        XCTAssertFalse(canGoBack)
    }

    func testEmptyBackList() {
        let canGoBack = BackListURLs.filteredCanGoBack(
            backURLs: [],
            current: URL(string: "https://kiwix.org#redirectedTo")!,
            skipList: [URL(string: "https://kiwix.org#redirectedTo")!: URL(string: "https://kiwix.org")!]
        )
        XCTAssertFalse(canGoBack)
    }

    func testEmptySkipList() {
        let canGoBack = BackListURLs.filteredCanGoBack(
            backURLs: [URL(string: "https://something.old")!],
            current: URL(string: "https://kiwix.org")!,
            skipList: [:]
        )
        XCTAssertTrue(canGoBack)
    }

    func testMatchingBackListReducedToEmpty() {
        let canGoBack = BackListURLs.filteredCanGoBack(
            backURLs: [URL(string: "https://kiwix.org")!],
            current: URL(string: "https://kiwix.org#redirectedTo")!,
            skipList: [URL(string: "https://kiwix.org#redirectedTo")!: URL(string: "https://kiwix.org")!]
        )
        XCTAssertFalse(canGoBack)
    }

    func testMatchingBackListReducedToNotEmpty() {
        let canGoBack = BackListURLs.filteredCanGoBack(
            backURLs: [URL(string: "https://something.old")!, URL(string: "https://kiwix.org")!],
            current: URL(string: "https://kiwix.org#redirectedTo")!,
            skipList: [URL(string: "https://kiwix.org#redirectedTo")!: URL(string: "https://kiwix.org")!]
        )
        XCTAssertTrue(canGoBack) // should skip https://kiwix.org, and be able to go back to https://something.old
    }

    func testNotMatchingSkipList_1() {
        let canGoBack = BackListURLs.filteredCanGoBack(
            backURLs: [URL(string: "https://something.old")!],
            current: URL(string: "https://kiwix.org#redirectedTo")!,
            skipList: [URL(string: "https://kiwix.org#redirectedTo")!: URL(string: "https://kiwix.org")!]
        )
        XCTAssertTrue(canGoBack)
    }
    
    func testNotMatchingSkipList_2() {
        let canGoBack = BackListURLs.filteredCanGoBack(
            backURLs: [URL(string: "https://kiwix.org")!, URL(string: "https://something.old")!],
            current: URL(string: "https://kiwix.org#redirectedTo")!,
            skipList: [URL(string: "https://kiwix.org#redirectedTo")!: URL(string: "https://kiwix.org")!]
        )
        XCTAssertTrue(canGoBack) // should be able to go back to https://something.old as that is in between
    }

}
