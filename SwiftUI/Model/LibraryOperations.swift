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
    static func open(url: URL) async -> ZimFileMetaStruct? {
        guard let fileURLBookmark = await ZimFileService.getFileURLBookmarkData(for: url),
                let metastruct = await ZimFileService.getMetaData(url: url) else { return nil }

        // revalidate the file
        do {
            try await ZimFileService.shared.revalidate(fileURLBookmark: fileURLBookmark, for: metastruct.fileID)
        } catch {
            return nil
        }

        // upsert zim file in the database
        await Database.shared.viewContext.perform {
            let predicate = NSPredicate(format: "fileID == %@", metastruct.fileID as CVarArg)
            let fetchRequest = ZimFile.fetchRequest(predicate: predicate)
            let context = Database.shared.viewContext
            guard let zimFile = try? fetchRequest.execute().first ?? ZimFile(context: context) else {
                return
            }
            LibraryOperations.configureZimFile(zimFile, metadata: metastruct)
            zimFile.fileURLBookmark = fileURLBookmark
            zimFile.isMissing = false
            if context.hasChanges {
                try? context.save()
            }
        }
        return metastruct
    }

    /// Revalidate ZIM files from url bookmark data
    /// Marks all missing zimfiles in the DB
    @MainActor
    static func reValidate() async {
        var successCount = 0
        let context = Database.shared.viewContext
        let request = ZimFile.fetchRequest(predicate: ZimFile.Predicate.isDownloaded())

        guard let zimFiles = try? context.fetch(request) else {
            return
        }

        for zimFile in zimFiles {
            guard let data = zimFile.fileURLBookmark else { return }

            let downloadPath = zimFile.downloadURL?.absoluteString ?? "unknown"
            do {
                if let data = try await ZimFileService.shared.revalidate(fileURLBookmark: data, for: zimFile.fileID) {
                    zimFile.fileURLBookmark = data
                }
                zimFile.isMissing = false
                successCount += 1
                Log.LibraryOperations.notice("""
ZIM file opened: \(zimFile.name, privacy: .public) |\
\(downloadPath, privacy: .public)
""")
            } catch ZimFileOpenError.missing {
                zimFile.isMissing = true
                Log.LibraryOperations.notice("""
ZIM file missing: \(zimFile.name, privacy: .public) |\
 \(downloadPath, privacy: .public)
""")
            } catch {
                zimFile.isMissing = true
                Log.LibraryOperations.notice("""
ZIM file cannot be opened: \(zimFile.name, privacy: .public) |\ 
\(downloadPath, privacy: .public) due to: \(error, privacy: .public)
""")
            }
        }
        await MainActor.run { 
            if context.hasChanges {
                try? context.save()
            }
        }
        Log.LibraryOperations.info(
            "Reopened \(successCount, privacy: .public) out of \(zimFiles.count, privacy: .public) zim files"
        )
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
    static func configureZimFile(_ zimFile: ZimFile, metadata: ZimFileMetaStruct) {
        zimFile.articleCount = metadata.articleCount
        zimFile.category = (Category(rawValue: metadata.category) ?? .other).rawValue
        zimFile.created = metadata.creationDate
        zimFile.fileDescription = metadata.fileDescription
        zimFile.fileID = metadata.fileID
        zimFile.flavor = metadata.flavor
        zimFile.hasDetails = metadata.hasDetails
        zimFile.hasPictures = metadata.hasPictures
        zimFile.hasVideos = metadata.hasVideos
        zimFile.languageCode = metadata.languageCodes
        zimFile.mediaCount = metadata.mediaCount
        zimFile.name = metadata.title
        zimFile.persistentID = metadata.groupIdentifier
        zimFile.requiresServiceWorkers = metadata.requiresServiceWorkers
        zimFile.size = metadata.size

        // Overwrite these, only if there are new values
        if let faviconURL = metadata.faviconURL { zimFile.faviconURL = faviconURL }
        if let faviconData = metadata.faviconData { zimFile.faviconData = faviconData }
        if let downloadURL = metadata.downloadURL { zimFile.downloadURL = downloadURL }
    }

    // MARK: - Deletion

    /// Unlink a zim file from library, delete associated bookmarks, and delete the file.
    /// - Parameter zimFile: the zim file to delete
    @ZimActor static func delete(zimFileID: UUID) async {
        guard let url = ZimFileService.shared.getFileURL(zimFileID: zimFileID) else { return }
        defer { try? FileManager.default.removeItem(at: url) }
        await LibraryOperations.unlink(zimFileID: zimFileID)
    }

    /// Unlink a zim file from library, delete associated bookmarks, but don't delete the file.
    /// - Parameter zimFile: the zim file to unlink
    @ZimActor static func unlink(zimFileID: UUID) async {
        ZimFileService.shared.close(fileID: zimFileID)
        await Database.shared.viewContext.perform {
            guard let zimFile = try? ZimFile.fetchRequest(fileID: zimFileID).execute().first else {
                return
            }
            let context = Database.shared.viewContext
            zimFile.bookmarks.forEach { context.delete($0) }
            zimFile.fileURLBookmark = nil
            zimFile.isMissing = false
            zimFile.isIntegrityChecked = nil
            zimFile.tabs.forEach { context.delete($0) }
            if context.hasChanges {
                try? context.save()
            }
        }
        
        let tabIds: [NSManagedObjectID] = await Database.shared.viewContext.perform {
            let tabIdsRequest = NSFetchRequest<NSManagedObjectID>(entityName: "Tab")
            tabIdsRequest.resultType = .managedObjectIDResultType
            do {
                let tabIds = try tabIdsRequest.execute()
                return tabIds
            } catch {
                return []
            }
        }
        
        // clear out all the browserViewModels of tabs no longer in use
        BrowserViewModel.keepOnlyTabsByIds(Set(tabIds))

        #if os(iOS)
        // make sure we won't end up without any tabs
        if tabIds.count == 0 {
            await Database.shared.viewContext.perform {
                let context = Database.shared.viewContext
                let tab = Tab(context: context)
                tab.created = Date()
                tab.lastOpened = Date()
                try? context.obtainPermanentIDs(for: [tab])
                try? context.save()
            }
        }
        #else
        await MainActor.run {
            NotificationCenter.keepOnlyTabs(Set(tabIds))
        }
        #endif
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
