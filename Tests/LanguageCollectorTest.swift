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

final class LanguageCollectorTest: XCTestCase {

    func testEmpty() {
        let collector = LanguageCollector()
        XCTAssertTrue(collector.languages().isEmpty)
    }

    func testInvalidEntriesIgnored() {
        let collector = LanguageCollector()
        collector.addLanguages(codes: "", count: 1)
        XCTAssertTrue(collector.languages().isEmpty)
        collector.addLanguages(codes: "invalid", count: 1)
        XCTAssertTrue(collector.languages().isEmpty)
        collector.addLanguages(codes: "more,invalid,entries", count: 2)
        XCTAssertTrue(collector.languages().isEmpty)
        collector.addLanguages(codes: "i_am,invalid,fra", count: 1)
        XCTAssertEqual(collector.languages().count, 1)
        XCTAssertEqual(collector.languages().first!.name, "French")
    }

    func testZeroAndNegativeCountsIgnored() {
        let collector = LanguageCollector()
        collector.addLanguages(codes: "eng", count: 0)
        XCTAssertTrue(collector.languages().isEmpty)
        collector.addLanguages(codes: "eng,fra", count: -1)
        XCTAssertTrue(collector.languages().isEmpty)
    }

    func testAddingSingleLanguage() {
        let collector = LanguageCollector()
        collector.addLanguages(codes: "eng", count: 1)
        XCTAssertEqual(collector.languages().count, 1)
        XCTAssertEqual(collector.languages().first!.name, "English")
        XCTAssertEqual(collector.languages().first!.code, "eng")
        XCTAssertEqual(collector.languages().first!.count, 1)
    }

    func testRepeatedLanguageCodesAreIgnored() {
        let collector = LanguageCollector()
        collector.addLanguages(codes: "eng,eng", count: 1)
        XCTAssertEqual(collector.languages().count, 1)
        XCTAssertEqual(collector.languages().first!.count, 1)
    }

    func testAddingMultipleLanguages() {
        let collector = LanguageCollector()
        collector.addLanguages(codes: "fra,eng", count: 1)
        XCTAssertEqual(collector.languages().count, 2)
        XCTAssertEqual(collector.languages().map { $0.name }, ["English", "French"])
    }

    func testAddingMultiLanguagesWithVariousCounts() {
        let collector = LanguageCollector()
        collector.addLanguages(codes: "fra,eng", count: 1)
        collector.addLanguages(codes: "spa,por,fra", count: 2)
        XCTAssertEqual(collector.languages().count, 4)
        XCTAssertEqual(collector.languages(), [
            Language(code: "eng", count: 1)!,
            Language(code: "fra", count: 3)!,
            Language(code: "por", count: 2)!,
            Language(code: "spa", count: 2)!
        ])
    }
}
