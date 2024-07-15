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

final class LevenshteinTests: XCTestCase {

//    private var levenshtein: Levenshtein!

    private let levenshtein = Levenshtein()

//    override func setUp() {
//        super.setUp()
//        levenshtein = Levenshtein()
//    }
//
//    override func tearDown() {
//        levenshtein = nil
//        super.tearDown()
//    }

    func testEmptyStrings() {
        let distance = levenshtein.calculate("", "")
        XCTAssertEqual(distance, 0, "Distance between two empty strings should be 0")
    }

    func testEmptyAndNonEmptyString() {
        let distance = levenshtein.calculate("", "abc")
        XCTAssertEqual(distance, 3, "Distance between empty string and 'abc' should be 3")
    }

    func testIdenticalStrings() {
        let distance = levenshtein.calculate("abc", "abc")
        XCTAssertEqual(distance, 0, "Distance between identical strings should be 0")
    }

    func testSingleCharacterDifference() {
        let distance = levenshtein.calculate("abc", "abd")
        XCTAssertEqual(distance, 1, "Distance between 'abc' and 'abd' should be 1")
    }

    func testSingleCharacterAddition() {
        let distance = levenshtein.calculate("abc", "abcd")
        XCTAssertEqual(distance, 1, "Distance between 'abc' and 'abcd' should be 1")
    }

    func testComplexCase() {
        let distance = levenshtein.calculate("kitten", "sitting")
        XCTAssertEqual(distance, 3, "Distance between 'kitten' and 'sitting' should be 3")
    }

    func testAnotherComplexCase() {
        let distance = levenshtein.calculate("flaw", "lawn")
        XCTAssertEqual(distance, 2, "Distance between 'flaw' and 'lawn' should be 2")
    }

    func testLargeInput() {
        let length: UInt32 = 1_000
        let largeA = largeRandomString(length: length)[...]
        let largeB = largeRandomString(length: length)[...]
        self.measure {
            let _ = levenshtein.calculate(largeA, largeB)
        }
    }

    private func largeRandomString(length: UInt32) -> String {
        let characters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        let limit: UInt32 = length + arc4random_uniform(length)
        var result = ""
        for _ in 0..<limit {
            let randomAlphaChar = characters[Int(arc4random_uniform(UInt32(characters.count)))]
            result.append(randomAlphaChar)
        }
        return result
    }
}
