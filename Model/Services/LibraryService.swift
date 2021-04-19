//
//  LibraryService.swift
//  Kiwix
//
//  Created by Chris Li on 4/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import os
#if canImport(UIKit)
import UIKit
#endif
import Defaults
import RealmSwift

class LibraryService {
    static let shared = LibraryService()
    
    private var faviconDataCache = [String: Data]()
    private let faviconDownloadSemaphore = DispatchSemaphore(value: 1)
    
    func isFileInDocumentDirectory(zimFileID: String) -> Bool {
        if let fileName = ZimFileService.shared.getFileURL(zimFileID: zimFileID)?.lastPathComponent,
            let documentDirectoryURL = try? FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let fileURL = documentDirectoryURL.appendingPathComponent(fileName)
            return FileManager.default.fileExists(atPath: fileURL.path)
        } else {
            return false
        }
    }
    
    func deleteOrUnlink(fileID: String) {
        // Update the database
        do {
            let database = try Realm()
            guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: fileID) else { return }
            try database.write {
                if zimFile.downloadURL == nil {
                    database.delete(zimFile)
                } else {
                    zimFile.state = .remote
                    zimFile.openInPlaceURLBookmark = nil
                }
            }
        } catch {}
        
        // Remove file if file is in app's document directory
        if let fileURL = ZimFileService.shared.getFileURL(zimFileID: fileID),
           let documentDirectoryURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
           FileManager.default.fileExists(atPath: documentDirectoryURL.appendingPathComponent(fileURL.lastPathComponent).path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // Close the file reader
        ZimFileService.shared.close(id: fileID)
    }
    
    // MARK: - Settings

    #if canImport(UIKit)
    static let autoUpdateInterval: TimeInterval = 3600.0 * 6
    var isAutoUpdateEnabled: Bool {
        get {
            return Defaults[.libraryAutoRefresh]
        }
        set(newValue) {
            Defaults[.libraryAutoRefresh] = newValue
            applyAutoUpdateSetting()
        }
    }

    func applyAutoUpdateSetting() {
        UIApplication.shared.setMinimumBackgroundFetchInterval(
            isAutoUpdateEnabled ? LibraryService.autoUpdateInterval : UIApplication.backgroundFetchIntervalNever
        )
    }
    #endif
    
    /// Apply zim file back up setting.
    /// Note: will only update zim files in app's docuemnt directory.
    /// - Parameter isBackupEnabled: if backup is enabled
    func applyBackupSetting(isBackupEnabled: Bool) {
        do {
            let directory = try FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
            )
            let urls = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isExcludedFromBackupKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
            ).filter({ $0.pathExtension.contains("zim") })
            try urls.forEach { url in
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = !isBackupEnabled
                var url = url
                try url.setResourceValues(resourceValues)
            }
        } catch {}
    }
    
    // MARK: - Favicon Download
    
    /// Download and save favicon data of a zim file.
    /// - Parameters:
    ///   - zimFileID: ID of a zim file
    ///   - url: URL of the favicon data
    func downloadFavicon(zimFileID: String, url: URL) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { self.faviconDownloadSemaphore.signal() }
            self.faviconDownloadSemaphore.wait()
            
            // cache the retrieved data or log the error if no data is retrieved
            guard let data = data else {
                os_log("Favicon download failed. File ID: %s. Error",
                       log: Log.LibraryService,
                       type: .error, zimFileID,
                       error?.localizedDescription ?? "Unknown")
                return
            }
            self.faviconDataCache[zimFileID] = data
            
            // save the retrieved data in batches
            if self.faviconDataCache.count >= 5 {
                self.flushFaviconDataCache()
            } else {
                let zimFileIDs = Set(self.faviconDataCache.keys)
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
                    guard zimFileIDs == Set(self.faviconDataCache.keys) else { return }
                    self.flushFaviconDataCache()
                }
            }
        }
        task.resume()
    }
    
    private func flushFaviconDataCache() {
        do {
            let database = try Realm()
            try database.write {
                for (zimFileID, faviconData) in faviconDataCache {
                    let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID)
                    zimFile?.faviconData = faviconData
                    self.faviconDataCache.removeValue(forKey: zimFileID)
                }
            }
        } catch {}
    }
}
