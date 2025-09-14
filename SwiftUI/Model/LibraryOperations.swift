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

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif
import CoreData
import os

import Defaults

struct LibraryOperations {
    private init() {}

    // MARK: - Open

    /// Open a zim file with url
    /// - Parameter url: url of the zim file
    @discardableResult
    static func open(url: URL, onComplete: (() -> Void)? = nil) async -> ZimFileMetaData? {
        guard let metadata = await ZimFileService.getMetaData(url: url),
              let fileURLBookmark = await ZimFileService.getFileURLBookmarkData(for: url) else { return nil }

        // open the file
        do {
            try await ZimFileService.shared.open(fileURLBookmark: fileURLBookmark, for: metadata.fileID)
        } catch {
            return nil
        }

        // upsert zim file in the database
        Database.shared.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            let predicate = NSPredicate(format: "fileID == %@", metadata.fileID as CVarArg)
            let fetchRequest = ZimFile.fetchRequest(predicate: predicate)
            guard let zimFile = try? context.fetch(fetchRequest).first ?? ZimFile(context: context) else { return }
            LibraryOperations.configureZimFile(zimFile, metadata: metadata)
            zimFile.fileURLBookmark = fileURLBookmark
            zimFile.isMissing = false
            if context.hasChanges { try? context.save() }
            Task {
                await MainActor.run {
                    onComplete?()
                }
            }
        }

        return metadata
    }

    /// Reopen zim files from url bookmark data.
    static func reopen() async {
        var successCount = 0
        let context = Database.shared.viewContext
        let request = ZimFile.fetchRequest(predicate: ZimFile.Predicate.isDownloaded)

        guard let zimFiles = try? context.fetch(request) else {
            return
        }

        for zimFile in zimFiles {
            guard let data = zimFile.fileURLBookmark else { return }

            do {
                if let data = try await ZimFileService.shared.open(fileURLBookmark: data, for: zimFile.fileID) {
                    zimFile.fileURLBookmark = data
                }
                zimFile.isMissing = false
                successCount += 1
            } catch ZimFileOpenError.missing {
                zimFile.isMissing = true
            } catch {
                zimFile.fileURLBookmark = nil
                zimFile.isMissing = false
            }
        }
        Task { @MainActor in
            if context.hasChanges {
                try? context.save()
            }
        }
        Log.LibraryOperations.info(
            "Reopened \(successCount, privacy: .public) out of \(zimFiles.count, privacy: .public) zim files"
        )
    }
    
    
    /// Marks all missing zimfiles in the DB
    static func markMissingZIMFiles() async {
        let zimFileURLs = await ZimFileService.shared.getZIMFileURLs()
        var missingIDs: [UUID] = []
        for (zimFileID, url) in zimFileURLs where !FileManager.default.fileExists(atPath: url.path) {
            missingIDs.append(zimFileID)
        }
        let context = Database.shared.viewContext
        let zimRequest = ZimFile.fetchRequest(fileIDs: missingIDs)
        guard let zimFiles = try? context.fetch(zimRequest) else {
            return
        }
        for zimFile in zimFiles where !zimFile.isMissing {
            zimFile.isMissing = true
        }
        await MainActor.run {
            if context.hasChanges {
                try? context.save()
            }
        }
    }

    /// Scan a directory and open available zim files inside it
    /// - Parameter url: directory to scan
    static func scanDirectory(_ url: URL) {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
        ).filter({ $0.pathExtension == "zim"}) else { return }
        Log.LibraryOperations.info("Discovered \(fileURLs.count, privacy: .public) probable zim files.")
        Task {
            for fileURL in fileURLs {
                await LibraryOperations.open(url: fileURL)
            }
        }
    }

    // MARK: - Configure

    /// Configure a zim file object based on its metadata.
    static func configureZimFile(_ zimFile: ZimFile, metadata: ZimFileMetaData) {
        zimFile.articleCount = metadata.articleCount.int64Value
        zimFile.category = (Category(rawValue: metadata.category) ?? .other).rawValue
        zimFile.created = metadata.creationDate
        zimFile.fileDescription = metadata.fileDescription
        zimFile.fileID = metadata.fileID
        zimFile.flavor = metadata.flavor
        zimFile.hasDetails = metadata.hasDetails
        zimFile.hasPictures = metadata.hasPictures
        zimFile.hasVideos = metadata.hasVideos
        zimFile.languageCode = metadata.languageCodes
        zimFile.mediaCount = metadata.mediaCount.int64Value
        zimFile.name = metadata.title
        zimFile.persistentID = metadata.groupIdentifier
        zimFile.requiresServiceWorkers = metadata.requiresServiceWorkers
        zimFile.size = metadata.size.int64Value

        // Overwrite these, only if there are new values
        if let faviconURL = metadata.faviconURL { zimFile.faviconURL = faviconURL }
        if let faviconData = metadata.faviconData { zimFile.faviconData = faviconData }
        if let downloadURL = metadata.downloadURL { zimFile.downloadURL = downloadURL }
    }

    // MARK: - Deletion

    /// Unlink a zim file from library, delete associated bookmarks, and delete the file.
    /// - Parameter zimFile: the zim file to delete
    @ZimActor static func delete(zimFileID: UUID) {
        guard let url = ZimFileService.shared.getFileURL(zimFileID: zimFileID) else { return }
        defer { try? FileManager.default.removeItem(at: url) }
        LibraryOperations.unlink(zimFileID: zimFileID)
    }

    /// Unlink a zim file from library, delete associated bookmarks, but don't delete the file.
    /// - Parameter zimFile: the zim file to unlink
    @ZimActor static func unlink(zimFileID: UUID) {
        ZimFileService.shared.close(fileID: zimFileID)
        Database.shared.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            guard let zimFile = try? ZimFile.fetchRequest(fileID: zimFileID).execute().first else { return }
            zimFile.bookmarks.forEach { context.delete($0) }
            if zimFile.downloadURL == nil {
                context.delete(zimFile)
            } else {
                zimFile.fileURLBookmark = nil
                zimFile.isMissing = false
            }
            zimFile.tabs.forEach { context.delete($0) }

            if let tabs = try? Tab.fetchRequest().execute() {
                let tabIds = tabs.map { $0.objectID }
                // clear out all the browserViewModels of tabs no longer in use
                BrowserViewModel.keepOnlyTabsByIds(Set(tabIds))

                #if os(iOS)
                // make sure we won't end up without any tabs
                if tabs.count == 0 {
                    let tab = Tab(context: context)
                    tab.created = Date()
                    tab.lastOpened = Date()
                    try? context.obtainPermanentIDs(for: [tab])
                }
                #else
                if context.hasChanges { try? context.save() }
                Task { @MainActor in
                    NotificationCenter.keepOnlyTabs(Set(tabIds))
                }
                #endif
            }
            if context.hasChanges { try? context.save() }
        }
    }

    // MARK: - Backup

    /// Apply iCloud backup setting on zim files in document directory.
    /// - Parameter isEnabled: if file should be included in backup
    static func applyFileBackupSetting(isEnabled: Bool? = nil) {
        do {
            let directory = try FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
            )
            let urls = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isExcludedFromBackupKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
            ).filter({ $0.pathExtension.contains("zim") })
            let backupDocumentDirectory = isEnabled ?? Defaults[.backupDocumentDirectory]
            try urls.forEach { url in
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = !backupDocumentDirectory
                var url = url
                try url.setResourceValues(resourceValues)
            }
            let status = backupDocumentDirectory ? "backing up" : "not backing up"
            let fileCount = urls.count
            Log.LibraryOperations.info(
                "Updated iCloud backup setting (\(status, privacy: .public)) on files: \(fileCount, privacy: .public)")
        } catch {
            Log.LibraryOperations.error(
                "Unable to change iCloud backup settings, due to \(error.localizedDescription, privacy: .public)")
        }
    }
}
