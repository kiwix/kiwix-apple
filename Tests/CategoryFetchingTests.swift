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

// swiftlint:disable force_try
final class CategoryFetchingTests: XCTestCase {
    
    override func setUpWithError() throws {
        try resetDB()
    }
    
    @MainActor
    func testFilteredOutByLanguage() throws {
        // insert a zimFile
        let context = Database.shared.viewContext
        var zimFile = ZimFile(context: context)
        let metadata = ZimFileMetaStruct.mock(languageCodes: "eng",
                                              category: Category.other.rawValue)
        LibraryOperations.configureZimFile(&zimFile, metadata: metadata)
        try? context.save()
        let request = NSFetchRequest<ZimFile>(entityName: ZimFile.entity().name!)
        request.predicate = ZimFilesCategory.buildPredicate(
            category: .other,
            searchText: "",
            languageCodes: Set(["x"])
        )
        let results = try! context.fetch(request)
        XCTAssertTrue(results.isEmpty)
    }
    
    @MainActor
    func testCanBeFoundByLanguage() throws {
        // insert a zimFile
        let context = Database.shared.viewContext
        var zimFile = ZimFile(context: context)
        let metadata = ZimFileMetaStruct.mock(languageCodes: "eng",
                                              category: Category.other.rawValue)
        LibraryOperations.configureZimFile(&zimFile, metadata: metadata)
        try? context.save()
        let request = NSFetchRequest<ZimFile>(entityName: ZimFile.entity().name!)
        request.predicate = ZimFilesCategory.buildPredicate(
            category: .other,
            searchText: "",
            languageCodes: Set(["eng"])
        )
        let results = try! context.fetch(request)
        XCTAssertEqual(results.count, 1)
    }
    
    @MainActor
    func testCanBeFoundByMultipleUserLanguages() throws {
        // insert a zimFile
        let context = Database.shared.viewContext
        var zimFile = ZimFile(context: context)
        let metadata = ZimFileMetaStruct.mock(languageCodes: "fra",
                                              category: Category.other.rawValue)
        LibraryOperations.configureZimFile(&zimFile, metadata: metadata)
        try? context.save()
        let request = NSFetchRequest<ZimFile>(entityName: ZimFile.entity().name!)
        request.predicate = ZimFilesCategory.buildPredicate(
            category: .other,
            searchText: "",
            languageCodes: Set(["eng", "deu", "fra", "ita", "por"])
        )
        let results = try! context.fetch(request)
        XCTAssertEqual(results.count, 1)
    }
    
    @MainActor
    func testCanBeFoundHavingMultiLanguagesWithASingleUserLanguage() throws {
        // insert a zimFile
        let context = Database.shared.viewContext
        var zimFile = ZimFile(context: context)
        let metadata = ZimFileMetaStruct.mock(languageCodes: "eng,fra,deu,nld,spa,ita,por,pol,ara,vie,kor",
                                              category: Category.other.rawValue)
        LibraryOperations.configureZimFile(&zimFile, metadata: metadata)
        try? context.save()
        let request = NSFetchRequest<ZimFile>(entityName: ZimFile.entity().name!)
        request.predicate = ZimFilesCategory.buildPredicate(
            category: .other,
            searchText: "",
            languageCodes: Set(["spa"])
        )
        let results = try! context.fetch(request)
        XCTAssertEqual(results.count, 1)
    }
    
    @MainActor
    func testCanBeFoundHavingMultiLanguageMatches() throws {
        // insert a zimFile
        let context = Database.shared.viewContext
        var zimFile = ZimFile(context: context)
        let metadata = ZimFileMetaStruct.mock(languageCodes: "eng,fra,deu,nld,spa,ita,por,pol,ara,vie,kor",
                                              category: Category.other.rawValue)
        LibraryOperations.configureZimFile(&zimFile, metadata: metadata)
        try? context.save()
        let request = NSFetchRequest<ZimFile>(entityName: ZimFile.entity().name!)
        request.predicate = ZimFilesCategory.buildPredicate(
            category: .other,
            searchText: "",
            languageCodes: Set(["nld", "por", "fra"])
        )
        let results = try! context.fetch(request)
        XCTAssertEqual(results.count, 1)
    }
    
    @MainActor
    func testFilteredOutByMultiToMultiLanguageMissMatch() throws {
        // insert a zimFile
        let context = Database.shared.viewContext
        var zimFile = ZimFile(context: context)
        let metadata = ZimFileMetaStruct.mock(languageCodes: "eng,fra,deu,nld,spa,ita",
                                              category: Category.other.rawValue)
        LibraryOperations.configureZimFile(&zimFile, metadata: metadata)
        try? context.save()
        let request = NSFetchRequest<ZimFile>(entityName: ZimFile.entity().name!)
        request.predicate = ZimFilesCategory.buildPredicate(
            category: .other,
            searchText: "",
            languageCodes: Set(["por", "pol", "ara", "vie", "kor"])
        )
        let results = try! context.fetch(request)
        XCTAssertTrue(results.isEmpty)
    }
    
    private func resetDB() throws {
        _ = try Database.shared.viewContext.execute(
            NSBatchDeleteRequest(
                fetchRequest: NSFetchRequest(entityName: ZimFile.entity().name!)
            )
        )
    }
    
}

private extension ZimFileMetaStruct {
    static func mock(fileID: UUID = UUID(),
                     groupIdentifier: String = "test_group_id",
                     title: String = "test ZIM title",
                     fileDescription: String = "test description for test ZIM file",
                     languageCodes: String,
                     category: String = "other",
                     creationDate: Date = .init(timeIntervalSince1970: 0),
                     size: Int64 = 1_234,
                     articleCount: Int64 = 99,
                     mediaCount: Int64 = 33,
                     creator: String = "unit_test_creator",
                     publisher: String = "unit_test_publisher",
                     hasDetails: Bool = false,
                     hasPictures: Bool = false,
                     hasVideos: Bool = false,
                     requiresServiceWorkers: Bool = false,
                     downloadURL: URL? = nil,
                     faviconURL: URL? = nil,
                     faviconData: Data? = nil,
                     flavor: String? = nil) -> ZimFileMetaStruct {
        ZimFileMetaStruct(
            fileID: fileID,
            groupIdentifier: groupIdentifier,
            title: title,
            fileDescription: fileDescription,
            languageCodes: languageCodes,
            category: category,
            creationDate: creationDate,
            size: size,
            articleCount: articleCount,
            mediaCount: mediaCount,
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
// swiftlint:enable force_try
