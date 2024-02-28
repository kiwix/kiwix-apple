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
