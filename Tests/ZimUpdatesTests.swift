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
import Defaults
import XCTest
@testable import Kiwix

private struct RecordState {
    let count: Int
    let missing: Bool?
    let hasBookmark: Bool
    let integrity: Bool?
}

private struct ReplacedState {
    let oldState: String
    let bookmarkHost: String?
    let bookmarkOwner: UUID?
}

// swiftlint:disable force_try
// swiftlint:disable:next type_body_length
final class ZimUpdatesTests: XCTestCase {

    private static let day: TimeInterval = 24 * 60 * 60
    private static let now = Date(timeIntervalSince1970: 1_700_000_000)
    private static let zimName = "wikipedia_en_all"
    private var zimName: String { Self.zimName }

    /// the real implementation, put back after a test injected its own
    private var defaultRemoveFile: (@ZimActor @Sendable (UUID) -> Bool)!

    override func setUpWithError() throws {
        defaultRemoveFile = ZimReplacement.removeFile
        try resetDB()
    }

    override func tearDownWithError() throws {
        ZimReplacement.removeFile = defaultRemoveFile
        try resetDB()
    }

    @MainActor
    func test_newerVersionWithSameNameAndFlavor_isMapped() throws {
        let old = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        let new = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        let updates = ZimUpdates.findUpdates(in: Database.shared.viewContext)
        XCTAssertEqual(updates, [old.fileID: new.fileID])
    }

    @MainActor
    func test_newestOfSeveralNewerVersions_isChosen() throws {
        let old = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 10)
        let newest = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 5)
        let updates = ZimUpdates.findUpdates(in: Database.shared.viewContext)
        XCTAssertEqual(updates[old.fileID], newest.fileID)
    }

    @MainActor
    func test_differentFlavor_isNotMapped() throws {
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        _ = Self.insert(name: zimName, flavor: "nopic", daysAgo: 1)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    @MainActor
    func test_differentName_isNotMapped() throws {
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        _ = Self.insert(name: "wikipedia_de_all", flavor: "maxi", daysAgo: 1)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    @MainActor
    func test_olderOrSameDate_isNotMapped() throws {
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30)
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 60)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    @MainActor
    func test_candidateAlreadyDownloaded_isNotMapped() throws {
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1, downloaded: true)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    @MainActor
    func test_candidateWithoutDownloadURL_isNotMapped() throws {
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1, downloadURL: nil)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    @MainActor
    func test_emptyAndNilFlavor_areTreatedAsTheSame() throws {
        // local files report a missing flavor as "", catalog entries as nil
        let old = Self.insert(name: zimName, flavor: "", daysAgo: 30, downloaded: true)
        let new = Self.insert(name: zimName, flavor: nil, daysAgo: 1)
        let updates = ZimUpdates.findUpdates(in: Database.shared.viewContext)
        XCTAssertEqual(updates, [old.fileID: new.fileID])
    }

    @MainActor
    func test_storedUpdates_areReadBackByFileID() throws {
        let old = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        let new = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        let upToDate = Self.insert(name: "wikipedia_fr_all", flavor: "maxi", daysAgo: 30, downloaded: true)

        let updates = ZimUpdates.findUpdates(in: Database.shared.viewContext)
        let stored = Dictionary(uniqueKeysWithValues: updates.map { ($0.key.uuidString, $0.value.uuidString) })

        XCTAssertEqual(ZimUpdates.availableUpdate(for: old.fileID, in: stored), new.fileID)
        XCTAssertNil(ZimUpdates.availableUpdate(for: upToDate.fileID, in: stored))
        XCTAssertEqual(ZimUpdates.fileIDsWithUpdates(in: stored), [old.fileID])
    }

    @MainActor
    func test_openedPredicate_updatesAvailable_listsOnlyDownloadedFilesWithUpdate() throws {
        let old = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        _ = Self.insert(name: "wikipedia_fr_all", flavor: "maxi", daysAgo: 30, downloaded: true)
        let context = Database.shared.viewContext
        let updates = ZimUpdates.findUpdates(in: context)
        Defaults[.zimUpdatesAvailable] = Dictionary(
            uniqueKeysWithValues: updates.map { ($0.key.uuidString, $0.value.uuidString) }
        )

        let request = ZimFile.fetchRequest(predicate: ZimFile.openedPredicate(showBy: .updatesAvailable))
        XCTAssertEqual(try! context.fetch(request).map(\.fileID), [old.fileID])

        // the other filters are unaffected
        let all = ZimFile.fetchRequest(predicate: ZimFile.openedPredicate(showBy: .all))
        XCTAssertEqual(try! context.fetch(all).count, 2)

        // the predicate captures the map when it is built, once the map is empty, so is a new filtered list
        Defaults[.zimUpdatesAvailable] = [:]
        let emptyRequest = ZimFile.fetchRequest(predicate: ZimFile.openedPredicate(showBy: .updatesAvailable))
        XCTAssertTrue(try! context.fetch(emptyRequest).isEmpty)
    }

    func test_showBy_toggleCycle_includesUpdatesAvailable() {
        var seen: [ZIMsShowBy] = []
        var current = ZIMsShowBy.all
        for _ in 0..<4 {
            seen.append(current)
            current = current.toggleNext()
        }
        XCTAssertEqual(seen, [.all, .onlyAvailable, .onlyMissing, .updatesAvailable])
        XCTAssertEqual(current, .all)
    }

    @MainActor
    func test_missingDownloadedFile_isMappedButNotListedByFilter() throws {
        let old = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        old.isMissing = true
        let new = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        let context = Database.shared.viewContext
        let updates = ZimUpdates.findUpdates(in: context)
        XCTAssertEqual(updates, [old.fileID: new.fileID])

        ZimUpdates.store(updates)
        let request = ZimFile.fetchRequest(predicate: ZimFile.openedPredicate(showBy: .updatesAvailable))
        XCTAssertTrue(try! context.fetch(request).isEmpty)
    }

    func test_refresh_storesUpdatesInDefaults() async throws {
        let (oldID, expected) = await MainActor.run { () -> (UUID, [String: String]) in
            let old = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
            let new = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 1)
            _ = Self.insert(name: "wikipedia_fr_all", flavor: "maxi", daysAgo: 30, downloaded: true)
            return (old.fileID, [old.fileID.uuidString: new.fileID.uuidString])
        }

        await ZimUpdates.refresh()

        let (stored, listed) = await MainActor.run { () -> ([String: String], [UUID]) in
            let request = ZimFile.fetchRequest(predicate: ZimFile.openedPredicate(showBy: .updatesAvailable))
            let results = (try? Database.shared.viewContext.fetch(request)) ?? []
            return (Defaults[.zimUpdatesAvailable], results.map(\.fileID))
        }
        XCTAssertEqual(stored, expected)
        XCTAssertEqual(listed, [oldID])
    }

    @MainActor
    func test_emptyPersistentID_neverMatches() throws {
        _ = Self.insert(name: "", flavor: "maxi", daysAgo: 30, downloaded: true)
        _ = Self.insert(name: "", flavor: "maxi", daysAgo: 1)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    @MainActor
    func test_twoDownloadedVersions_bothMapToNewestCatalogEntry() throws {
        let old = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        let mid = Self.insert(name: zimName, flavor: "maxi", daysAgo: 10, downloaded: true)
        let newest = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        let updates = ZimUpdates.findUpdates(in: Database.shared.viewContext)
        XCTAssertEqual(updates, [old.fileID: newest.fileID, mid.fileID: newest.fileID])
    }

    func test_malformedUUIDStrings_areDropped() {
        let good = UUID()
        let stored = [good.uuidString: "not-a-uuid", "also-bad": UUID().uuidString]
        XCTAssertNil(ZimUpdates.availableUpdate(for: good, in: stored))
        XCTAssertEqual(ZimUpdates.fileIDsWithUpdates(in: stored), [good])
    }

    func test_deleteFileKeepingRecord_marksMissingAndKeepsRecord() async throws {
        let fileID = await MainActor.run { () -> UUID in
            let zimFile = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
            zimFile.isIntegrityChecked = true
            try? Database.shared.viewContext.save()
            return zimFile.fileID
        }
        ZimReplacement.removeFile = { _ in true }

        let deleted = await ZimReplacement.deleteFileKeepingRecord(oldFileID: fileID)

        XCTAssertTrue(deleted)
        let state = await MainActor.run { () -> RecordState in
            let all = (try? Database.shared.viewContext.fetch(ZimFile.fetchRequest(fileID: fileID))) ?? []
            let total = (try? Database.shared.viewContext.count(for: ZimFile.fetchRequest())) ?? -1
            return RecordState(count: total, missing: all.first?.isMissing,
                               hasBookmark: all.first?.fileURLBookmark != nil,
                               integrity: all.first?.isIntegrityChecked)
        }
        XCTAssertEqual(state.count, 1)
        XCTAssertEqual(state.missing, true)
        XCTAssertTrue(state.hasBookmark)
        XCTAssertNil(state.integrity)
    }

    func test_deleteFileKeepingRecord_reportsFailureAndLeavesTheRecordAlone() async throws {
        let fileID = await MainActor.run { () -> UUID in
            let zimFile = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
            zimFile.isIntegrityChecked = true
            try? Database.shared.viewContext.save()
            return zimFile.fileID
        }
        ZimReplacement.removeFile = { _ in false } // e.g. a read only security scoped file on macOS

        let deleted = await ZimReplacement.deleteFileKeepingRecord(oldFileID: fileID)

        XCTAssertFalse(deleted)
        let state = await MainActor.run { () -> RecordState in
            let all = (try? Database.shared.viewContext.fetch(ZimFile.fetchRequest(fileID: fileID))) ?? []
            return RecordState(count: all.count, missing: all.first?.isMissing,
                               hasBookmark: all.first?.fileURLBookmark != nil,
                               integrity: all.first?.isIntegrityChecked)
        }
        XCTAssertEqual(state.missing, false,
                       "the record must not be marked missing while the file is still there")
        XCTAssertTrue(state.hasBookmark)
        XCTAssertEqual(state.integrity, true, "nothing at all should have changed")
    }

    func test_replace_migratesBookmarksAndUnlinksOldRecord_evenWhenTheFileStays() async throws {
        let (oldID, newID) = await MainActor.run { () -> (UUID, UUID) in
            let context = Database.shared.viewContext
            let old = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
            let new = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 1, downloaded: true)
            let bookmark = Bookmark(context: context)
            bookmark.articleURL = URL(string: "kiwix://\(old.fileID.uuidString)/wb/Saftladen")!
            bookmark.title = "Saftladen"
            bookmark.created = Date()
            bookmark.zimFile = old
            try? context.save()
            return (old.fileID, new.fileID)
        }
        ZimReplacement.removeFile = { _ in false }

        await ZimReplacement.replace(oldFileID: oldID, with: newID)

        let result = await MainActor.run { () -> ReplacedState in
            let context = Database.shared.viewContext
            let old = (try? context.fetch(ZimFile.fetchRequest(fileID: oldID)))?.first
            let bookmark = (try? context.fetch(Bookmark.fetchRequest()))?.first
            let state: String = if let old {
                old.fileURLBookmark == nil ? "unlinked" : "still linked"
            } else {
                "deleted"
            }
            return ReplacedState(oldState: state, bookmarkHost: bookmark?.articleURL.host(),
                                 bookmarkOwner: bookmark?.zimFile?.fileID)
        }
        XCTAssertEqual(result.oldState, "unlinked",
                       "the old record is unlinked, not deleted, so no list or selection holding it can trap")
        XCTAssertEqual(result.bookmarkOwner, newID)
        XCTAssertEqual(result.bookmarkHost, newID.uuidString)
    }

    // MARK: - Helpers

    @MainActor
    @discardableResult
    private static func insert(name: String,
                               flavor: String?,
                               daysAgo: Double,
                               downloaded: Bool = false,
                               downloadURL: URL? = URL(string: "https://download.kiwix.org/zim/test.zim.meta4")
    ) -> ZimFile {
        let context = Database.shared.viewContext
        let zimFile = ZimFile(context: context)
        let metadata = ZimFileMetaStruct(
            fileID: UUID(),
            groupIdentifier: name,
            title: "Test ZIM",
            fileDescription: "test description",
            languageCodes: "eng",
            category: Category.wikipedia.rawValue,
            creationDate: now.addingTimeInterval(-daysAgo * day),
            size: 1_000,
            articleCount: 10,
            mediaCount: 5,
            creator: "test",
            publisher: "test",
            downloadURL: downloadURL,
            faviconURL: nil,
            faviconData: nil,
            flavor: flavor,
            hasDetails: false,
            hasPictures: false,
            hasVideos: false,
            requiresServiceWorkers: false
        )
        LibraryOperations.configureZimFile(zimFile, metadata: metadata)
        if downloaded {
            zimFile.fileURLBookmark = Data([0x01])
        }
        try! context.save()
        return zimFile
    }

    /// Deletes through the context (not a batch delete), so the app's fetched results controllers
    /// observing the view context see proper deletions instead of dangling objects.
    private func resetDB() throws {
        let context = Database.shared.viewContext
        try context.fetch(Bookmark.fetchRequest()).forEach { context.delete($0) }
        try context.fetch(ZimFile.fetchRequest()).forEach { context.delete($0) }
        if context.hasChanges { try context.save() }
        Defaults[.zimUpdatesAvailable] = [:]
    }
}
// swiftlint:enable force_try
