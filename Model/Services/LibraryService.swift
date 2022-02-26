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
    
    class func onDeviceZimFiles() -> Results<ZimFile>? {
        do {
            let database = try Realm()
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }
    
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
        guard let fileID = UUID(uuidString: fileID) else { return }
        ZimFileService.shared.close(fileID: fileID)
    }
    
    // MARK: - Settings

    #if canImport(UIKit)
    static let autoUpdateInterval: TimeInterval = 3600.0 * 6
    static var isOutdated: Bool {
        guard let lastRefresh = Defaults[.libraryLastRefresh] else { return true }
        return Date().timeIntervalSince(lastRefresh) > LibraryService.autoUpdateInterval
    }
    
    func applyAutoUpdateSetting() {
        UIApplication.shared.setMinimumBackgroundFetchInterval(
            Defaults[.libraryAutoRefresh] ? LibraryService.autoUpdateInterval : UIApplication.backgroundFetchIntervalNever
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
}
