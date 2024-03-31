/*
 * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

//
//  LanguagesConverterTests.swift
//  UnitTests

import XCTest
@testable import Kiwix

final class LanguagesConverterTests: XCTestCase {
    func testShouldHaveEmptyResult() {
        let empty: Set<String> = .init()

        XCTAssertEqual(LanguagesConverter.convert(
            codes: empty,
            validCodes: empty
        ), empty)

        XCTAssertEqual(LanguagesConverter.convert(
            codes: empty,
            validCodes: .init(["eng", "fra"])
        ), empty)
    }

    func testShouldFilterOutInvalidOnes() {
        let empty: Set<String> = .init()
        XCTAssertEqual(LanguagesConverter.convert(
            codes: .init(["invalid 1", "invalid 2"]),
            validCodes: .init(["eng", "fra"])
        ),
        empty)

        XCTAssertEqual(LanguagesConverter.convert(
            codes: .init(["invalid 1", "eng", "invalid 2"]),
            validCodes: .init(["eng", "fra"])
        ),
        .init(["eng"]))
    }

    func testConversion() {
        XCTAssertEqual(LanguagesConverter.convertToAlpha3(from: "ab"), "abk")
        XCTAssertEqual(LanguagesConverter.convertToAlpha3(from: "ha"), "hau")
        XCTAssertEqual(LanguagesConverter.convertToAlpha3(from: "en"), "eng")
        XCTAssertEqual(LanguagesConverter.convertToAlpha3(from: "zh"), "zho")
        XCTAssertEqual(LanguagesConverter.convertToAlpha3(from: "zu"), "zul")
    }

    func testShouldConvertValidOnes() {
        XCTAssertEqual(LanguagesConverter.convert(
            codes: .init(["en"]),
            validCodes: .init(["fra", "ita", "eng"])
        ),
        .init(["eng"]))
    }

    func testShouldLeaveInAlpha3Ones() {
        XCTAssertEqual(LanguagesConverter.convert(
            codes: .init(["fr", "eng", "invalid"]),
            validCodes: .init(["fra", "ita", "eng"])
        ),
        .init(["eng", "fra"]))
    }

    func testShouldIntersectToOnlyValidCodes() {
        XCTAssertEqual(LanguagesConverter.convert(
            codes: .init(["fr", "eng", "it"]),
            validCodes: .init(["spa", "fin", "ita"])
        ),
        .init(["ita"]))
    }
}
