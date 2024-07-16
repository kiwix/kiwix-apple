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

import CoreData
import XCTest
import SwiftUI
@testable import Kiwix

final class CategoryFetchingTests: XCTestCase {

    func testSingleZIMIsFilteredOutByLanguage() throws {
        // insert a zimFile
        let context = Database.viewContext
        let zimFile = ZimFile(context: context)
        let metadata = ZimFileMetaData.mock(languageCodes: "en", category: Category.other.rawValue)
        LibraryOperations.configureZimFile(zimFile, metadata: metadata)
        try? context.save()
        let request = NSFetchRequest<ZimFile>(entityName: ZimFile.entity().name!)
        request.predicate = ZimFilesCategory.buildPredicate(category: .other, searchText: "", languageCodes: Set(["xx"]))
        let results = try! context.fetch(request)
        XCTAssertTrue(results.isEmpty)
    }

    func testSingleZIMCanBeFoundByLanguage() throws {
        // insert a zimFile
        let context = Database.viewContext
        let zimFile = ZimFile(context: context)
        let metadata = ZimFileMetaData.mock(languageCodes: "en", category: Category.other.rawValue)
        LibraryOperations.configureZimFile(zimFile, metadata: metadata)
        try? context.save()
        let request = NSFetchRequest<ZimFile>(entityName: ZimFile.entity().name!)
        request.predicate = ZimFilesCategory.buildPredicate(category: .other, searchText: "", languageCodes: Set(["en"]))
        let results = try! context.fetch(request)
        XCTAssertEqual(results.count, 1)
    }

}

private extension ZimFileMetaData {
    static func mock(fileID: UUID = UUID(),
                     groupIdentifier: String = "test_group_id",
                     title: String = "test ZIM title",
                     fileDescription: String = "test description for test ZIM file",
                     languageCodes: String,
                     category: String = "other",
                     creationDate: Date = .init(timeIntervalSince1970: 0),
                     size: UInt = 1_234,
                     articleCount: UInt = 99,
                     mediaCount: UInt = 33,
                     creator: String = "unit_test_creator",
                     publisher: String = "unit_test_publisher",
                     hasDetails: Bool = false,
                     hasPictures: Bool = false,
                     hasVideos: Bool = false,
                     requiresServiceWorkers: Bool = false,
                     downloadURL: URL? = nil,
                     faviconURL: URL? = nil,
                     faviconData: Data? = nil,
                     flavor: String? = nil) -> ZimFileMetaData {
        ZimFileMetaData(
            fileID: fileID,
            groupIdentifier: groupIdentifier,
            title: title,
            fileDescription: fileDescription,
            languageCodes: languageCodes,
            category: category,
            creationDate: creationDate,
            size: NSNumber(value: size),
            articleCount: NSNumber(value: articleCount),
            mediaCount: NSNumber(value: mediaCount),
            creator: creator,
            publisher: publisher,
            downloadURL: downloadURL,
            faviconURL: faviconURL,
            faviconData: faviconData,
            flavor: flavor,
            hasDetails: hasDetails,
            hasPictures: hasPictures,
            hasVideos: hasVideos,
            requiresServiceWorkers: requiresServiceWorkers
        )
    }
}
