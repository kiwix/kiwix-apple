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
import Foundation

/// How an update of a downloaded ZIM file should be carried out
enum ZimUpdateStrategy: Equatable {
    /// Download the new version first, keep the current one usable, delete it once the download succeeded
    case keepUntilDone
    /// Delete the current version first, to free up space, then download the new version
    case deleteFirst

    /// Picks the strategy that fits into the available space
    /// - Parameters:
    ///   - freeSpace: available space in bytes, nil if it cannot be determined
    ///   - newSize: size of the new version in bytes
    ///   - oldSize: size of the currently downloaded version in bytes
    ///   - canDeleteOld: false when the current file cannot be removed by the app,
    ///   in which case deleting it first is not an option, and its size cannot be counted on
    /// - Returns: nil if no preselection can be made (unknown space, or not enough space either way)
    static func preselect(freeSpace: Int64?,
                          newSize: Int64,
                          oldSize: Int64,
                          canDeleteOld: Bool) -> ZimUpdateStrategy? {
        guard let freeSpace else { return nil }
        if freeSpace >= newSize {
            return .keepUntilDone
        } else if canDeleteOld, freeSpace + oldSize >= newSize {
            return .deleteFirst
        } else {
            return nil
        }
    }

    /// False, when the new version does not fit, even after deleting the current one (if that is possible at all)
    static func canProceed(freeSpace: Int64?, newSize: Int64, oldSize: Int64, canDeleteOld: Bool) -> Bool {
        guard let freeSpace else { return true } // unknown space: let the user decide
        guard canDeleteOld else { return freeSpace >= newSize }
        return freeSpace + oldSize >= newSize
    }
}

/// Replaces a downloaded ZIM file with a newer version:
/// bookmarks and tabs are migrated to the new version, the old file is deleted.
///
/// A replacement can be pending, while the new version is being downloaded (in the background),
/// this is tracked in `Defaults[.pendingZimReplacements]` as new fileID -> old fileID.
enum ZimReplacement {

    static func setPending(newFileID: UUID, oldFileID: UUID) {
        Defaults[.pendingZimReplacements][newFileID.uuidString] = oldFileID.uuidString
    }

    static func pendingOldFileID(for newFileID: UUID) -> UUID? {
        Defaults[.pendingZimReplacements][newFileID.uuidString].flatMap(UUID.init(uuidString:))
    }

    static func clearPending(newFileID: UUID) {
        Defaults[.pendingZimReplacements][newFileID.uuidString] = nil
    }

    /// Completes a pending replacement, if there is one for the given (freshly downloaded) file
    static func completePendingIfNeeded(newFileID: UUID) async {
        guard let oldFileID = pendingOldFileID(for: newFileID) else { return }
        await replace(oldFileID: oldFileID, with: newFileID)
        clearPending(newFileID: newFileID)
    }

    /// Removes the file of a downloaded ZIM file from disk and closes its reader.
    ///
    /// Injectable, so that tests can drive both outcomes without a ZIM file on disk.
    /// - Returns: true when the file is gone afterwards
    nonisolated(unsafe) static var removeFile: @ZimActor @Sendable (UUID) -> Bool = removeFileOnDisk(fileID:)

    /// Whether the app is able to remove the given file.
    ///
    /// This is only a hint, taken before offering the user a choice.
    /// Whether `isDeletableFile` also reflects a sandbox denial (on macOS the per file bookmark is
    /// security scoped and read only, see `ZimFileService.getFileURLBookmarkData`) is not verified,
    /// which is why both this hint and the real outcome of `removeFileOnDisk` are logged.
    /// Should the hint turn out to be inaccurate, replace the body with a probe
    /// (for instance a rename in place and back), the signature stays the same.
    static func canDeleteFile(at url: URL) -> Bool {
        let needsScope = url.startAccessingSecurityScopedResource()
        defer { if needsScope { url.stopAccessingSecurityScopedResource() } }
        let canDelete = FileManager.default.isDeletableFile(atPath: url.path(percentEncoded: false))
        Log.DownloadService.notice("""
ZIM file removal: deletable hint = \(canDelete, privacy: .public) \
for: \(url.path(percentEncoded: false), privacy: .private)
""")
        return canDelete
    }

    /// Whether the app is able to remove the file of the given downloaded ZIM file
    @ZimActor
    static func canDeleteFile(of fileID: UUID) -> Bool {
        guard let url = ZimFileService.shared.getFileURL(zimFileID: fileID) else { return false }
        return canDeleteFile(at: url)
    }

    /// The file path of a downloaded ZIM file, to be named in the UI when it could not be removed
    @ZimActor
    static func filePath(of fileID: UUID) -> String? {
        ZimFileService.shared.getFileURL(zimFileID: fileID)?.path(percentEncoded: false)
    }

    /// Removes the ZIM file, and closes its reader when it is gone.
    /// The removal is attempted before closing, so that a failure leaves everything as it was.
    ///
    /// On macOS the file goes to the Trash, so that the user keeps a way back if the newer
    /// version disappoints. `removeItem` stays as the fallback for a volume without a Trash,
    /// and is the only mechanism on iOS, where there is no Trash the user can see and a trashed
    /// file would go on consuming the very storage the delete first option exists to free.
    ///
    /// The fallback is not a way around a refusal: it was measured on macOS that where a direct
    /// removal is refused for permission reasons, trashing is refused for the same reason, and
    /// so is `NSWorkspace.recycle`. A file outside our writable area is out of reach either way,
    /// which `canDeleteFile` decides up front. Please do not reintroduce a chain of attempts.
    @ZimActor
    private static func removeFileOnDisk(fileID: UUID) -> Bool {
        guard let url = ZimFileService.shared.getFileURL(zimFileID: fileID) else {
            Log.DownloadService.notice(
                "ZIM file removal: no file known for: \(fileID.uuidString, privacy: .public)"
            )
            return false
        }
        let needsScope = url.startAccessingSecurityScopedResource()
        defer { if needsScope { url.stopAccessingSecurityScopedResource() } }
        let path = url.path(percentEncoded: false)
        #if os(macOS)
        do {
            var trashedURL: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &trashedURL)
            ZimFileService.shared.close(fileID: fileID)
            Log.DownloadService.notice("ZIM file removal: trashItem succeeded for: \(path, privacy: .private)")
            return true
        } catch {
            Log.DownloadService.notice("""
ZIM file removal: trashItem failed for: \(path, privacy: .private) \
due to: \(error.localizedDescription, privacy: .public)
""")
        }
        #endif
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            Log.DownloadService.notice("""
ZIM file removal: removeItem failed for: \(path, privacy: .private) \
due to: \(error.localizedDescription, privacy: .public)
""")
            return false
        }
        ZimFileService.shared.close(fileID: fileID)
        Log.DownloadService.notice("ZIM file removal: removeItem succeeded for: \(path, privacy: .private)")
        return true
    }

    /// Deletes the old file from disk to free up space, but keeps its DB record (marked as missing),
    /// so that its bookmarks and tabs survive until the new version is downloaded and can take them over.
    /// The record is not unlinked, otherwise the next catalog sync would delete it along with the bookmarks.
    /// - Returns: false when the file could not be removed, in that case nothing was changed at all,
    /// and the caller must not start a replacing download
    @ZimActor
    @discardableResult
    static func deleteFileKeepingRecord(oldFileID: UUID) async -> Bool {
        guard removeFile(oldFileID) else { return false }
        await Database.shared.viewContext.perform {
            let context = Database.shared.viewContext
            let request = ZimFile.fetchRequest(fileID: oldFileID)
            request.fetchLimit = 1
            guard let zimFile = try? request.execute().first else { return }
            zimFile.isMissing = true
            zimFile.isIntegrityChecked = nil
            if context.hasChanges { try? context.save() }
        }
        return true
    }

    /// Moves bookmarks from the old to the new ZIM file, removes the old file,
    /// and unlinks the old DB record, the same way the app's own Unlink action does.
    /// Tabs showing the old version are closed by that unlink, as they are today:
    /// a live web view keeps its own history, so pointing a tab at the new version
    /// would leave it with back entries that can no longer load.
    ///
    /// The old record is deliberately not deleted: the app's lists and selections hold on to
    /// downloaded records, and deleting one out from under them traps. Unlinking takes it out
    /// of every list through the same predicate the app already uses, and the next catalog sync
    /// sweeps the leftover row along with every other non-downloaded one.
    /// A leftover file (one the app was not allowed to remove) is reported to the user.
    @ZimActor
    static func replace(oldFileID: UUID, with newFileID: UUID) async {
        let oldFilePath = filePath(of: oldFileID)
        let removed = removeFile(oldFileID)
        await Database.shared.viewContext.perform {
            let context = Database.shared.viewContext
            let oldRequest = ZimFile.fetchRequest(fileID: oldFileID)
            oldRequest.fetchLimit = 1
            let newRequest = ZimFile.fetchRequest(fileID: newFileID)
            newRequest.fetchLimit = 1
            guard let oldZimFile = try? oldRequest.execute().first,
                  let newZimFile = try? newRequest.execute().first else { return }
            ZimMigration.moveBookmarks(from: oldZimFile, to: newZimFile, using: context)
        }
        // closes the reader, clears cookies and the file link, and refreshes the update map
        await LibraryOperations.unlink(zimFileID: oldFileID)
        if !removed, let oldFilePath {
            DownloadUI.showAlert(.zimFileNotRemoved(path: oldFilePath))
        }
    }

    /// Free space in the folder where downloads are stored
    static func freeSpace() -> Int64? {
        guard let folder = DownloadDestination.downloadLocalFolder() else { return nil }
        return try? folder
            .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            .volumeAvailableCapacityForImportantUsage
    }
}
