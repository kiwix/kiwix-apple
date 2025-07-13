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

// swiftlint:disable force_try
final class DatabaseTests: XCTestCase {

    /// Make sure our test database behaves the same way as the real one
    func xtestDatabases() throws {
        let database: Databasing = Database.shared
        let testDB = TestDatabase()
        
        // insertion
        let id1 = UUID()
        let id2 = UUID()
        
        var zimFileIDs = Set([id1, id2])
        let insertCount = try database.context.bulkInsert { zimFile in
            while !zimFileIDs.isEmpty {
                guard let id = zimFileIDs.popFirst() else { continue }
                let metadata = Self.metadata(for: id)
                LibraryOperations.configureZimFile(zimFile, metadata: metadata)
                return false
            }
            return true
        }
    
        var uuids = Set([id1, id2])
        let testInsertCount = try testDB.context.bulkInsert { zimFile in
            while !uuids.isEmpty {
                guard let id = uuids.popFirst() else { continue }
                let metadata = Self.metadata(for: id)
                LibraryOperations.configureZimFile(zimFile, metadata: metadata)
                return false
            }
            return true
        }
        
        XCTAssertEqual(insertCount, testInsertCount)
        
        // test fetching
        let zimFiles = try! database.context.fetchZimFiles()
        XCTAssertEqual(zimFiles.count, 2)
        XCTAssertEqual(try! testDB.context.fetchZimFiles().count, 2)
    
        // test deletion
        let noDeleteCount = try! database.context.bulkDeleteNotDownloadedZims(notIncludedIn: [id1, id2])
        let testNoDeleteCount = try! testDB.context.bulkDeleteNotDownloadedZims(notIncludedIn: [id1, id2])
        
        XCTAssertEqual(noDeleteCount, 0)
        XCTAssertEqual(testNoDeleteCount, 0)
        
        let deleteCount = try! database.context.bulkDeleteNotDownloadedZims(notIncludedIn: [])
        let testDeleteCount = try! testDB.context.bulkDeleteNotDownloadedZims(notIncludedIn: [])
        
        XCTAssertEqual(deleteCount, 2)
        XCTAssertEqual(testDeleteCount, 2)
        
        XCTAssertEqual(try! database.context.fetchZimFiles().count, 0)
        XCTAssertEqual(try! testDB.context.fetchZimFiles().count, 0)
        
    }
    
    private static func metadata(for uuid: UUID) -> ZimFileMetaData {
        ZimFileMetaData(
            fileID: uuid,
            groupIdentifier: "group",
            title: "test-title",
            fileDescription: "desc",
            languageCodes: "en",
            category: "meta",
            creationDate: .now,
            size: 11,
            articleCount: 1,
            mediaCount: 1,
            creator: "me",
            publisher: "me",
            downloadURL: nil,
            faviconURL: nil,
            faviconData: nil,
            flavor: nil,
            hasDetails: false,
            hasPictures: false,
            hasVideos: false,
            requiresServiceWorkers: false
        )
    }
}
// swiftlint:enable force_try
