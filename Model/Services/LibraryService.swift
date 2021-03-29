//
//  LibraryService.swift
//  Kiwix
//
//  Created by Chris Li on 4/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif
import Defaults
import RealmSwift

class LibraryService {
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
}
