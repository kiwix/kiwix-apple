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
//  BookmarkMigrationTests.swift
//  UnitTests

import XCTest
@testable import Kiwix

// swiftlint:disable force_cast
final class BookmarkMigrationTests: XCTestCase {

    func testURLHostChange() throws {
        let url = URL(string: "kiwix://64C3EA1A-5161-2B94-1F50-606DA5EC0035/wb/Saftladen")!
        let newHost: String = UUID(uuidString: "A992BF76-CA94-6B60-A762-9B5BC89B5BBF")!.uuidString
        let expectedURL = URL(string: "kiwix://A992BF76-CA94-6B60-A762-9B5BC89B5BBF/wb/Saftladen")!
        XCTAssertEqual(url.updateHost(to: newHost), expectedURL)
    }

    func testURLUpdatesInData() throws {
        let newHost: String = UUID(uuidString: "A992BF76-CA94-6B60-A762-9B5BC89B5BBF")!.uuidString
        // swiftlint:disable:next line_length
        let testString = "\0\0\0\u{02}bplist00�\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}^RenderTreeSize^IsAppInitiated^SessionHistory\u{10}\u{03}\t�\u{07}\u{08}\t\n\u{1C}\u{1C}_\u{10}\u{15}SessionHistoryEntries_\u{10}\u{1A}SessionHistoryCurrentIndex_\u{10}\u{15}SessionHistoryVersion�\u{0B}\u{16}�\u{0C}\r\u{0E}\u{0F}\u{10}\u{11}\u{12}\u{13}\u{14}\u{15}_\u{10}\u{17}SessionHistoryEntryData_\u{10}\u{18}SessionHistoryEntryTitle_\u{10}2SessionHistoryEntryShouldOpenExternalURLsPolicyKey_\u{10}\u{16}SessionHistoryEntryURL_\u{10}\u{1E}SessionHistoryEntryOriginalURLO\u{10}P\0\0\0\0\0\0\0\0\u{02}\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0�\u{07}�@�\u{13}\u{06}\0\0\0\0\0\0\0\0\0����\0\0\0\0�\u{07}�@�\u{13}\u{06}\0����\0\0\0\0�\u{03}\0\0\0\0�?\0\0\0\0����TDWDS\u{10}\u{01}_\u{10}2kiwix://64C3EA1A-5161-2B94-1F50-606DA5EC0035/index_\u{10}2kiwix://64C3EA1A-5161-2B94-1F50-606DA5EC0035/index�\u{0C}\r\u{0E}\u{0F}\u{10}\u{17}\u{18}\u{19}\u{1A}\u{1B}O\u{10}P\0\0\0\0\0\0\0\0\u{02}\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0V<�A�\u{13}\u{06}\0\0\0\0\0\0\0\0\0����\0\0\0\0U<�A�\u{13}\u{06}\0����\0\0\0\0\0\0\0\0\0\0�?\0\0\0\0����[hier und da\u{10}\u{02}_\u{10}<kiwix://64C3EA1A-5161-2B94-1F50-606DA5EC0035/wb/hie_.und_.da_\u{10}<kiwix://64C3EA1A-5161-2B94-1F50-606DA5EC0035/wb/hie_.und_.da\u{10}\u{01}\0\u{08}\0\u{0F}\0\u{1E}\0-\0<\0>\0?\0F\0^\0{\0�\0�\0�\0�\0�\u{01}\u{0B}\u{01}$\u{01}E\u{01}�\u{01}�\u{01}�\u{01}�\u{02}\t\u{02}\u{14}\u{02}g\u{02}s\u{02}u\u{02}�\u{02}�\0\0\0\0\0\0\u{02}\u{01}\0\0\0\0\0\0\0\u{1D}\0\0\0\0\0\0\0\0\0\0\0\0\0\0\u{02}�"
        let data = Data(testString.utf8)
        let newData = data.updateHost(to: newHost)
        let outString = String(bytes: newData, encoding: .utf8)!
        XCTAssertFalse(outString.contains("64C3EA1A-5161-2B94-1F50-606DA5EC0035"))
        XCTAssertTrue(outString.contains(newHost))
        // swiftlint:disable:next line_length
        let expectedString = "\0\0\0\u{02}bplist00�\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}^RenderTreeSize^IsAppInitiated^SessionHistory\u{10}\u{03}\t�\u{07}\u{08}\t\n\u{1C}\u{1C}_\u{10}\u{15}SessionHistoryEntries_\u{10}\u{1A}SessionHistoryCurrentIndex_\u{10}\u{15}SessionHistoryVersion�\u{0B}\u{16}�\u{0C}\r\u{0E}\u{0F}\u{10}\u{11}\u{12}\u{13}\u{14}\u{15}_\u{10}\u{17}SessionHistoryEntryData_\u{10}\u{18}SessionHistoryEntryTitle_\u{10}2SessionHistoryEntryShouldOpenExternalURLsPolicyKey_\u{10}\u{16}SessionHistoryEntryURL_\u{10}\u{1E}SessionHistoryEntryOriginalURLO\u{10}P\0\0\0\0\0\0\0\0\u{02}\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0�\u{07}�@�\u{13}\u{06}\0\0\0\0\0\0\0\0\0����\0\0\0\0�\u{07}�@�\u{13}\u{06}\0����\0\0\0\0�\u{03}\0\0\0\0�?\0\0\0\0����TDWDS\u{10}\u{01}_\u{10}2kiwix://A992BF76-CA94-6B60-A762-9B5BC89B5BBF/index_\u{10}2kiwix://A992BF76-CA94-6B60-A762-9B5BC89B5BBF/index�\u{0C}\r\u{0E}\u{0F}\u{10}\u{17}\u{18}\u{19}\u{1A}\u{1B}O\u{10}P\0\0\0\0\0\0\0\0\u{02}\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0V<�A�\u{13}\u{06}\0\0\0\0\0\0\0\0\0����\0\0\0\0U<�A�\u{13}\u{06}\0����\0\0\0\0\0\0\0\0\0\0�?\0\0\0\0����[hier und da\u{10}\u{02}_\u{10}<kiwix://A992BF76-CA94-6B60-A762-9B5BC89B5BBF/wb/hie_.und_.da_\u{10}<kiwix://A992BF76-CA94-6B60-A762-9B5BC89B5BBF/wb/hie_.und_.da\u{10}\u{01}\0\u{08}\0\u{0F}\0\u{1E}\0-\0<\0>\0?\0F\0^\0{\0�\0�\0�\0�\0�\u{01}\u{0B}\u{01}$\u{01}E\u{01}�\u{01}�\u{01}�\u{01}�\u{02}\t\u{02}\u{14}\u{02}g\u{02}s\u{02}u\u{02}�\u{02}�\0\0\0\0\0\0\u{02}\u{01}\0\0\0\0\0\0\0\u{1D}\0\0\0\0\0\0\0\0\0\0\0\0\0\0\u{02}�"
        XCTAssertEqual(outString, expectedString)
    }

    func test_scheme_change() {
        let url = URL(string: "kiwix://64C3EA1A-5161-2B94-1F50-606DA5EC0035/wb/Saftladen")!
        XCTAssertEqual(url.updatedToZIMSheme(), URL(string: "zim://64C3EA1A-5161-2B94-1F50-606DA5EC0035/wb/Saftladen")!)
    }
}
// swiftlint:enable force_cast
