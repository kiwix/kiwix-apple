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

import Defaults
import XCTest
@testable import Kiwix

final class ReplacementStrategyTests: XCTestCase {

    // swiftlint:disable:next identifier_name
    private let gb: Int64 = 1_000_000_000

    override func tearDownWithError() throws {
        Defaults[.pendingZimReplacements] = [:]
    }

    func test_boundary_oneByteUnderKeepThreshold_isDeleteFirst() {
        XCTAssertEqual(
            ZimUpdateStrategy.preselect(freeSpace: 8 * gb - 1, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true),
            .deleteFirst
        )
    }

    func test_boundary_oneByteUnderDeleteFirstThreshold_cannotProceed() {
        XCTAssertNil(
            ZimUpdateStrategy.preselect(freeSpace: 1 * gb - 1, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true)
        )
        XCTAssertFalse(
            ZimUpdateStrategy.canProceed(freeSpace: 1 * gb - 1, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true)
        )
    }

    func test_notDeletableCurrentVersion_neverPreselectsDeleteFirst() {
        // it would fit after deleting the current one, but the app cannot remove that file
        XCTAssertNil(
            ZimUpdateStrategy.preselect(freeSpace: 3 * gb, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: false)
        )
        XCTAssertFalse(
            ZimUpdateStrategy.canProceed(freeSpace: 3 * gb, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: false)
        )
    }

    func test_notDeletableCurrentVersion_stillKeepsWhenTheNewVersionFitsBesideIt() {
        XCTAssertEqual(
            ZimUpdateStrategy.preselect(freeSpace: 10 * gb, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: false),
            .keepUntilDone
        )
        XCTAssertTrue(
            ZimUpdateStrategy.canProceed(freeSpace: 10 * gb, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: false)
        )
    }

    func test_unknownFreeSpace_isUndecidedRegardlessOfDeletability() {
        XCTAssertNil(
            ZimUpdateStrategy.preselect(freeSpace: nil, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: false)
        )
        XCTAssertTrue(
            ZimUpdateStrategy.canProceed(freeSpace: nil, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: false)
        )
    }

    func test_clearingOnePendingReplacement_keepsTheOther() {
        let (newA, oldA, newB, oldB) = (UUID(), UUID(), UUID(), UUID())
        ZimReplacement.setPending(newFileID: newA, oldFileID: oldA)
        ZimReplacement.setPending(newFileID: newB, oldFileID: oldB)

        ZimReplacement.clearPending(newFileID: newA)

        XCTAssertNil(ZimReplacement.pendingOldFileID(for: newA))
        XCTAssertEqual(ZimReplacement.pendingOldFileID(for: newB), oldB)
    }

    func test_completePendingIfNeeded_withoutEntry_leavesOtherEntriesUntouched() {
        let (newA, newB, oldB) = (UUID(), UUID(), UUID())
        ZimReplacement.setPending(newFileID: newB, oldFileID: oldB)

        let done = expectation(description: "completePendingIfNeeded")
        Task {
            await ZimReplacement.completePendingIfNeeded(newFileID: newA)
            done.fulfill()
        }
        wait(for: [done], timeout: 5)

        XCTAssertEqual(ZimReplacement.pendingOldFileID(for: newB), oldB)
    }

    func test_keepUntilDone_whenNewVersionFits() {
        XCTAssertEqual(
            ZimUpdateStrategy.preselect(freeSpace: 10 * gb, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true),
            .keepUntilDone
        )
        XCTAssertTrue(
            ZimUpdateStrategy.canProceed(freeSpace: 10 * gb, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true)
        )
    }

    func test_keepUntilDone_whenNewVersionFitsExactly() {
        XCTAssertEqual(
            ZimUpdateStrategy.preselect(freeSpace: 8 * gb, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true),
            .keepUntilDone
        )
    }

    func test_deleteFirst_whenNewVersionFitsOnlyAfterDeletingCurrent() {
        XCTAssertEqual(
            ZimUpdateStrategy.preselect(freeSpace: 3 * gb, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true),
            .deleteFirst
        )
        XCTAssertTrue(
            ZimUpdateStrategy.canProceed(freeSpace: 3 * gb, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true)
        )
    }

    func test_deleteFirst_whenFitsExactlyAfterDeletingCurrent() {
        XCTAssertEqual(
            ZimUpdateStrategy.preselect(freeSpace: 1 * gb, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true),
            .deleteFirst
        )
    }

    func test_noStrategy_whenNotEnoughSpaceEvenAfterDeleting() {
        XCTAssertNil(ZimUpdateStrategy.preselect(freeSpace: 0, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true))
        XCTAssertFalse(ZimUpdateStrategy.canProceed(freeSpace: 0, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true))
    }

    func test_noPreselection_butCanProceed_whenFreeSpaceUnknown() {
        XCTAssertNil(ZimUpdateStrategy.preselect(freeSpace: nil, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true))
        XCTAssertTrue(
            ZimUpdateStrategy.canProceed(freeSpace: nil, newSize: 8 * gb, oldSize: 7 * gb, canDeleteOld: true)
        )
    }

    func test_pendingReplacements_roundTrip() {
        let newID = UUID()
        let oldID = UUID()
        ZimReplacement.clearPending(newFileID: newID)
        XCTAssertNil(ZimReplacement.pendingOldFileID(for: newID))

        ZimReplacement.setPending(newFileID: newID, oldFileID: oldID)
        XCTAssertEqual(ZimReplacement.pendingOldFileID(for: newID), oldID)

        ZimReplacement.clearPending(newFileID: newID)
        XCTAssertNil(ZimReplacement.pendingOldFileID(for: newID))
    }
}
