//
//  BookmarkMigrationTests.swift
//  UnitTests

import XCTest
@testable import Kiwix

final class BookmarkMigrationTests: XCTestCase {

    func testURLHostChange() throws {
        let url = URL(string: "kiwix://64C3EA1A-5161-2B94-1F50-606DA5EC0035/wb/Saftladen")!
        let newHost: String = UUID(uuidString: "A992BF76-CA94-6B60-A762-9B5BC89B5BBF")!.uuidString
        let expectedURL = URL(string: "kiwix://A992BF76-CA94-6B60-A762-9B5BC89B5BBF/wb/Saftladen")!
        XCTAssertEqual(url.updateHost(to: newHost), expectedURL)
    }
}
