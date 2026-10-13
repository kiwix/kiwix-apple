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
    let bookmarkOwner: UUID?
}

private struct ReplacedState {
    let oldState: String
    let bookmarkCount: Int
    let bookmarkHost: String?
    let bookmarkOwner: UUID?
    let tabsOnOld: Int
    let tabsOnNew: Int
}

// swiftlint:disable force_try file_length
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
    func test_newerVersionWithSameTitleIDAndFlavor_isMapped() throws {
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
    func test_differentTitle_isNotMapped() throws {
        // name and title ID both differ here, test_sameNameButDifferentTitleID_isNotMapped tells the two apart
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        _ = Self.insert(name: "wikipedia_de_all", flavor: "maxi", daysAgo: 1)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    @MainActor
    func test_sameNameButDifferentTitleID_isNotMapped() throws {
        // e.g. two publishers using the same ZIM name for unrelated content
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        _ = Self.insert(name: zimName, titleID: "title-other-publisher", flavor: "maxi", daysAgo: 1)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    @MainActor
    func test_renamedTitle_withSameTitleID_isMapped() throws {
        // the catalog keeps the title ID when a title is renamed, e.g. proofwiki_en_all -> proofwiki.org_en_all
        let old = Self.insert(name: "proofwiki_en_all", flavor: "maxi", daysAgo: 30, downloaded: true)
        let new = Self.insert(name: "proofwiki.org_en_all",
                              titleID: Self.titleID(for: "proofwiki_en_all"),
                              flavor: "maxi",
                              daysAgo: 1)
        let updates = ZimUpdates.findUpdates(in: Database.shared.viewContext)
        XCTAssertEqual(updates, [old.fileID: new.fileID])
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
    func test_nilAndEmptyFlavor_areTreatedAsTheSame() throws {
        let old = Self.insert(name: zimName, flavor: nil, daysAgo: 30, downloaded: true)
        let new = Self.insert(name: zimName, flavor: "", daysAgo: 1)
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
    func test_downloadedFileWithoutTitleID_hasNoUpdate() throws {
        // a sideloaded file, or one downloaded before the catalog had title IDs
        let old = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        Self.setTitleID(nil, on: old)
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    @MainActor
    func test_filesWithoutTitleID_neverMatchEachOther() throws {
        let old = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        let new = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        Self.setTitleID(nil, on: old, new)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)

        Self.setTitleID("", on: old, new)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    @MainActor
    func test_catalogEntryWithoutTitleID_isNeverAnUpdate() throws {
        _ = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        let new = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        Self.setTitleID(nil, on: new)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)

        Self.setTitleID("", on: new)
        XCTAssertTrue(ZimUpdates.findUpdates(in: Database.shared.viewContext).isEmpty)
    }

    // MARK: - Storing the title ID

    @MainActor
    func test_configure_storesTitleID_andNeverClearsIt() throws {
        let zimFile = ZimFile(context: Database.shared.viewContext)
        let fileID = UUID()
        LibraryOperations.configureZimFile(zimFile, metadata: Self.metadata(fileID: fileID, titleID: "T"))
        XCTAssertEqual(zimFile.titleID, "T")

        // re-opening the downloaded file: the ZIM itself carries no title ID
        LibraryOperations.configureZimFile(zimFile, metadata: Self.metadata(fileID: fileID, titleID: nil))
        XCTAssertEqual(zimFile.titleID, "T")
        LibraryOperations.configureZimFile(zimFile, metadata: Self.metadata(fileID: fileID, titleID: ""))
        XCTAssertEqual(zimFile.titleID, "T")

        // a new value from the catalog does replace it
        LibraryOperations.configureZimFile(zimFile, metadata: Self.metadata(fileID: fileID, titleID: "U"))
        XCTAssertEqual(zimFile.titleID, "U")
    }

    @MainActor
    func test_adoptTitleIDs_fillsDownloadedFilesStillInTheCatalog() throws {
        let context = Database.shared.viewContext
        let old = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        Self.setTitleID(nil, on: old)
        let new = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        XCTAssertTrue(ZimUpdates.findUpdates(in: context).isEmpty)

        let catalog = [
            old.fileID: Self.metadata(fileID: old.fileID, titleID: Self.titleID(for: zimName)),
            new.fileID: Self.metadata(fileID: new.fileID, titleID: Self.titleID(for: zimName))
        ]
        XCTAssertEqual(ZimUpdates.adoptTitleIDs(from: catalog, in: context), 1)
        XCTAssertEqual(old.titleID, Self.titleID(for: zimName))
        // once adopted, the newer release is found
        XCTAssertEqual(ZimUpdates.findUpdates(in: context), [old.fileID: new.fileID])
    }

    @MainActor
    func test_adoptTitleIDs_leavesOtherRecordsAlone() throws {
        let context = Database.shared.viewContext
        let notInCatalog = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        let notDownloaded = Self.insert(name: zimName, flavor: "maxi", daysAgo: 1)
        Self.setTitleID(nil, on: notInCatalog, notDownloaded)
        let keepsItsID = Self.insert(name: "wikipedia_fr_all", flavor: "maxi", daysAgo: 30, downloaded: true)
        let keepsItsIDToo = Self.insert(name: "wikipedia_es_all", flavor: "maxi", daysAgo: 30, downloaded: true)

        let otherRelease = UUID()
        let catalog = [
            notDownloaded.fileID: Self.metadata(fileID: notDownloaded.fileID, titleID: "T"),
            keepsItsID.fileID: Self.metadata(fileID: keepsItsID.fileID, titleID: nil),
            keepsItsIDToo.fileID: Self.metadata(fileID: keepsItsIDToo.fileID, titleID: ""),
            // same title as notInCatalog, but a different release: matching is by fileID only
            otherRelease: Self.metadata(fileID: otherRelease, titleID: Self.titleID(for: zimName))
        ]
        XCTAssertEqual(ZimUpdates.adoptTitleIDs(from: catalog, in: context), 0)
        XCTAssertNil(notInCatalog.titleID)
        XCTAssertNil(notDownloaded.titleID, "catalog rows get their title ID when inserted, not here")
        XCTAssertEqual(keepsItsID.titleID, Self.titleID(for: "wikipedia_fr_all"))
        XCTAssertEqual(keepsItsIDToo.titleID, Self.titleID(for: "wikipedia_es_all"))
    }

    @MainActor
    func test_adoptTitleIDs_countsOnlyChangedRecords() throws {
        let context = Database.shared.viewContext
        let unchanged = Self.insert(name: zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
        let reassigned = Self.insert(name: "wikipedia_fr_all", flavor: "maxi", daysAgo: 30, downloaded: true)

        let catalog = [
            unchanged.fileID: Self.metadata(fileID: unchanged.fileID, titleID: Self.titleID(for: zimName)),
            reassigned.fileID: Self.metadata(fileID: reassigned.fileID, titleID: "title-reassigned")
        ]
        // the catalog is the authority: a different value replaces the stored one
        XCTAssertEqual(ZimUpdates.adoptTitleIDs(from: catalog, in: context), 1)
        XCTAssertEqual(unchanged.titleID, Self.titleID(for: zimName))
        XCTAssertEqual(reassigned.titleID, "title-reassigned")
    }

    func test_metaStruct_hasNoTitleIDUntilLibkiwixProvidesIt() throws {
        // replace with a real value once kiwix/libkiwix#1356 is available
        let metadata = ZimFileMetaData(
            fileID: UUID(), groupIdentifier: zimName, title: "Test ZIM", fileDescription: "test",
            languageCodes: "eng", category: "wikipedia", creationDate: Self.now,
            size: 1_000, articleCount: 10, mediaCount: 5, creator: "test", publisher: "test", tags: "",
            downloadURL: nil, faviconURL: nil, faviconData: nil, flavor: "maxi",
            hasDetails: false, hasPictures: false, hasVideos: false, requiresServiceWorkers: false
        )
        let metaStruct = try XCTUnwrap(ZimFileService.metaStruct(from: metadata))
        XCTAssertEqual(metaStruct.flavor, "maxi")
        XCTAssertNil(metaStruct.titleID)
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

    func test_deleteFileKeepingRecord_marksMissingAndKeepsRecordAndItsBookmarks() async throws {
        let fileID = await MainActor.run { () -> UUID in
            let context = Database.shared.viewContext
            let zimFile = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
            zimFile.isIntegrityChecked = true
            Self.insertBookmark(on: zimFile)
            try? context.save()
            return zimFile.fileID
        }
        ZimReplacement.removeFile = { _ in true }

        let deleted = await ZimReplacement.deleteFileKeepingRecord(oldFileID: fileID)

        XCTAssertTrue(deleted)
        let state = await MainActor.run { () -> RecordState in
            let context = Database.shared.viewContext
            let all = (try? context.fetch(ZimFile.fetchRequest(fileID: fileID))) ?? []
            let total = (try? context.count(for: ZimFile.fetchRequest())) ?? -1
            let bookmark = (try? context.fetch(Bookmark.fetchRequest()))?.first
            return RecordState(count: total, missing: all.first?.isMissing,
                               hasBookmark: all.first?.fileURLBookmark != nil,
                               integrity: all.first?.isIntegrityChecked,
                               bookmarkOwner: bookmark?.zimFile?.fileID)
        }
        XCTAssertEqual(state.count, 1)
        XCTAssertEqual(state.missing, true)
        XCTAssertTrue(state.hasBookmark)
        XCTAssertNil(state.integrity)
        XCTAssertEqual(state.bookmarkOwner, fileID, "the record is kept so that its bookmarks survive the download")
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
                               integrity: all.first?.isIntegrityChecked,
                               bookmarkOwner: nil)
        }
        XCTAssertEqual(state.count, 1)
        XCTAssertEqual(state.missing, false,
                       "the record must not be marked missing while the file is still there")
        XCTAssertTrue(state.hasBookmark)
        XCTAssertEqual(state.integrity, true, "nothing at all should have changed")
    }

    func test_replace_migratesBookmarksAndUnlinksOldRecord_whenTheFileWasRemoved() async throws {
        await assertReplace(fileRemoved: true)
    }

    func test_replace_migratesBookmarksAndUnlinksOldRecord_evenWhenTheFileStays() async throws {
        await assertReplace(fileRemoved: false)
    }

    private func assertReplace(fileRemoved: Bool) async {
        let (oldID, newID) = await MainActor.run { () -> (UUID, UUID) in
            let context = Database.shared.viewContext
            let old = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
            let new = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 1, downloaded: true)
            Self.insertBookmark(on: old)
            let tab = Tab(context: context)
            tab.created = Date()
            tab.lastOpened = Date()
            tab.zimFile = old
            try? context.save()
            return (old.fileID, new.fileID)
        }
        Defaults[.zimUpdatesAvailable] = [oldID.uuidString: newID.uuidString]
        ZimReplacement.removeFile = { _ in fileRemoved }

        await ZimReplacement.replace(oldFileID: oldID, with: newID)

        let result = await MainActor.run { () -> ReplacedState in
            let context = Database.shared.viewContext
            let old = (try? context.fetch(ZimFile.fetchRequest(fileID: oldID)))?.first
            let new = (try? context.fetch(ZimFile.fetchRequest(fileID: newID)))?.first
            let bookmarks = (try? context.fetch(Bookmark.fetchRequest())) ?? []
            let state: String = if let old {
                old.fileURLBookmark == nil ? "unlinked" : "still linked"
            } else {
                "deleted"
            }
            return ReplacedState(oldState: state,
                                 bookmarkCount: bookmarks.count,
                                 bookmarkHost: bookmarks.first?.articleURL.host(),
                                 bookmarkOwner: bookmarks.first?.zimFile?.fileID,
                                 tabsOnOld: old?.tabs.count ?? -1,
                                 tabsOnNew: new?.tabs.count ?? -1)
        }
        XCTAssertEqual(result.oldState, "unlinked",
                       "the old record is unlinked, not deleted, so no list or selection holding it can trap")
        XCTAssertEqual(result.bookmarkCount, 1, "the bookmark is moved, neither duplicated nor deleted")
        XCTAssertEqual(result.bookmarkOwner, newID)
        XCTAssertEqual(result.bookmarkHost, newID.uuidString)
        XCTAssertEqual(result.tabsOnOld, 0, "tabs showing the old version are closed by the unlink")
        XCTAssertEqual(result.tabsOnNew, 0, "tabs are not moved over: a live web view keeps its own history")
        XCTAssertTrue(Defaults[.zimUpdatesAvailable].isEmpty, "the replaced file no longer has an update")
    }

    func test_completePendingIfNeeded_replacesAndClearsThePendingEntry() async throws {
        let (oldID, newID) = await MainActor.run { () -> (UUID, UUID) in
            let old = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 30, downloaded: true)
            let new = Self.insert(name: Self.zimName, flavor: "maxi", daysAgo: 1, downloaded: true)
            try? Database.shared.viewContext.save()
            return (old.fileID, new.fileID)
        }
        ZimReplacement.setPending(newFileID: newID, oldFileID: oldID)
        ZimReplacement.removeFile = { _ in true }

        await ZimReplacement.completePendingIfNeeded(newFileID: newID)

        XCTAssertNil(ZimReplacement.pendingOldFileID(for: newID), "a completed replacement is no longer pending")
        let oldIsLinked = await MainActor.run { () -> Bool? in
            let old = (try? Database.shared.viewContext.fetch(ZimFile.fetchRequest(fileID: oldID)))?.first
            return old.map { $0.fileURLBookmark != nil }
        }
        XCTAssertEqual(oldIsLinked, false, "the old record is unlinked once the replacement completed")
    }

    // MARK: - Helpers

    @MainActor
    @discardableResult
    private static func insertBookmark(on zimFile: ZimFile) -> Bookmark {
        let bookmark = Bookmark(context: Database.shared.viewContext)
        bookmark.articleURL = URL(string: "kiwix://\(zimFile.fileID.uuidString)/wb/Saftladen")!
        bookmark.title = "Saftladen"
        bookmark.created = Date()
        bookmark.zimFile = zimFile
        return bookmark
    }

    /// sets the title ID directly, bypassing configureZimFile which never clears it, and saves like insert does
    @MainActor
    private static func setTitleID(_ titleID: String?, on zimFiles: ZimFile...) {
        zimFiles.forEach { $0.titleID = titleID }
        try! Database.shared.viewContext.save()
    }

    /// a stable title ID per ZIM name, so books with different names are different titles unless a test says otherwise
    private static func titleID(for name: String) -> String {
        "title-\(name)"
    }

    // swiftlint:disable:next function_parameter_count
    @discardableResult
    private static func insert(name: String,
                               titleID: String? = nil,
                               flavor: String?,
                               daysAgo: Double,
                               downloaded: Bool = false,
                               downloadURL: URL? = URL(string: "https://download.kiwix.org/zim/test.zim.meta4")
    ) -> ZimFile {
        let context = Database.shared.viewContext
        let zimFile = ZimFile(context: context)
        let metadata = metadata(name: name,
                                titleID: titleID ?? Self.titleID(for: name),
                                flavor: flavor,
                                daysAgo: daysAgo,
                                downloadURL: downloadURL)
        LibraryOperations.configureZimFile(zimFile, metadata: metadata)
        if downloaded {
            zimFile.fileURLBookmark = Data([0x01])
        }
        try! context.save()
        return zimFile
    }

    // swiftlint:disable:next function_parameter_count
    private static func metadata(fileID: UUID = UUID(),
                                 name: String = zimName,
                                 titleID: String?,
                                 flavor: String? = "maxi",
                                 daysAgo: Double = 1,
                                 downloadURL: URL? = URL(string: "https://download.kiwix.org/zim/test.zim.meta4")
    ) -> ZimFileMetaStruct {
        ZimFileMetaStruct(
            fileID: fileID,
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
            tags: [],
            downloadURL: downloadURL,
            faviconURL: nil,
            faviconData: nil,
            flavor: flavor,
            titleID: titleID,
            hasDetails: false,
            hasPictures: false,
            hasVideos: false,
            requiresServiceWorkers: false
        )
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
