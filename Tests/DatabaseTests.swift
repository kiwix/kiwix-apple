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
    func xtestDatabases() async throws {
        let database: Databasing = ProductionDatabase()
        let testDB = TestDatabase()
        
        // insertion
        let id1 = UUID()
        let id2 = UUID()
        
        let zimFileIDs = Set([id1, id2])
        let metadata = zimFileIDs.map { Self.metadata(for: $0) }
        
        let insertCount = try await database.bulkInsert(metadata: metadata)
        let testInsertCount = try await testDB.bulkInsert(metadata: metadata)
        
        XCTAssertEqual(insertCount, testInsertCount)
        
        // test fetching
        let zimFiles = try! await database.fetchZimFileIds()
        XCTAssertEqual(zimFiles.count, 2)
        let testZimFiles = try! await testDB.fetchZimFileIds()
        XCTAssertEqual(testZimFiles.count, 2)
    
        // test deletion
        let noDeleteCount = try! await database.bulkDeleteNotDownloadedZims(notIncludedIn: [id1, id2])
        let testNoDeleteCount = try! await testDB.bulkDeleteNotDownloadedZims(notIncludedIn: [id1, id2])
        
        XCTAssertEqual(noDeleteCount, 0)
        XCTAssertEqual(testNoDeleteCount, 0)
        
        let deleteCount = try! await database.bulkDeleteNotDownloadedZims(notIncludedIn: [])
        let testDeleteCount = try! await testDB.bulkDeleteNotDownloadedZims(notIncludedIn: [])
        
        XCTAssertEqual(deleteCount, 2)
        XCTAssertEqual(testDeleteCount, 2)
        
        let fileCount = try! await database.fetchZimFileIds().count
        let testFileCount = try! await testDB.fetchZimFileIds().count
        XCTAssertEqual(fileCount, 0)
        XCTAssertEqual(testFileCount, 0)
    }
    
    private static func metadata(for uuid: UUID) -> ZimFileMetaStruct {
        ZimFileMetaStruct(
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
