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

final class OrderedCacheTests: XCTestCase {

    @MainActor
    func testEmpty() {
        let cache = OrderedCache<String, String>()
        XCTAssertEqual(cache.count, 0)
        XCTAssertNil(cache.findBy(key: "not to be found"))
    }

    @MainActor
    func testOneItem() {
        let cache = OrderedCache<String, String>()
        let pastDate = Date.distantPast
        cache.setValue("test_value", forKey: "keyOne", dated: pastDate)
        XCTAssertEqual(cache.count, 1)
        XCTAssertNil(cache.findBy(key: "not to be found"))
        XCTAssertEqual(cache.findBy(key: "keyOne"), "test_value")
        cache.removeOlderThan(pastDate)
        XCTAssertEqual(cache.count, 1)
        cache.removeOlderThan(Date.now)
        XCTAssertEqual(cache.count, 0)
    }

    @MainActor
    func testRemoveOlderThan() {
        let cache = OrderedCache<String, String>()
        let nowDate = Date.now
        cache.setValue("test_value", forKey: "keyOne", dated: nowDate)
        cache.setValue("old_value", forKey: "keyOld", dated: Date.distantPast)
        XCTAssertEqual(cache.count, 2)
        cache.removeOlderThan(nowDate.advanced(by: -1))
        XCTAssertEqual(cache.count, 1)
    }

    @MainActor
    func testRemoveByKey() {
        let cache = OrderedCache<String, Int>()
        cache.setValue(1, forKey: "one")
        cache.setValue(0, forKey: "zero")
        cache.removeValue(forKey: "zero")
        XCTAssertNil(cache.findBy(key: "zero"))
        XCTAssertEqual(cache.findBy(key: "one"), 1)
    }

    @MainActor
    func testRemoveByNotMatchingKeys() {
        let cache = OrderedCache<String, Int>()
        cache.setValue(101, forKey: "one_zero_one")
        cache.setValue(1, forKey: "one")
        cache.setValue(202, forKey: "two_zero_two")
        let removed = cache.removeNotMatchingWith(keys: Set<String>(["some", "one", "else"]))
        XCTAssertEqual(cache.count, 1)
        XCTAssertNil(cache.findBy(key: "zero"))
        XCTAssertEqual(cache.findBy(key: "one"), 1)
        XCTAssertEqual(removed.count, 2)
        XCTAssertTrue(removed.contains(101))
        XCTAssertTrue(removed.contains(202))
    }

}
