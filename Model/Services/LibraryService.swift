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

class LibraryService {
    func isFileInDocumentDirectory(zimFileID: String) -> Bool {
        if let fileName = ZimMultiReader.shared.getFileURL(zimFileID: zimFileID)?.lastPathComponent,
            let documentDirectoryURL = try? FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let fileURL = documentDirectoryURL.appendingPathComponent(fileName)
            return FileManager.default.fileExists(atPath: fileURL.path)
        } else {
            return false
        }
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
