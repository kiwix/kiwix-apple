//
//  LibraryService.swift
//  Kiwix
//
//  Created by Chris Li on 4/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

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
    
    // MARK: - Auto Update
    
    static let autoUpdateInterval: TimeInterval = 3600.0 * 6
    
    @SwiftyUserDefault(keyPath: \.libraryAutoRefresh)
    var isAutoUpdateEnabled: Bool {
        didSet { applyAutoUpdateSetting() }
    }

    func applyAutoUpdateSetting() {
        UIApplication.shared.setMinimumBackgroundFetchInterval(
            isAutoUpdateEnabled ? LibraryService.autoUpdateInterval : UIApplication.backgroundFetchIntervalNever
        )
    }
}

extension DefaultsKeys {
    fileprivate var libraryAutoRefresh: DefaultsKey<Bool> { .init("libraryAutoRefresh", defaultValue: true) }
    var libraryLastRefreshTime: DefaultsKey<Date?> { .init("libraryLastRefreshTime") }
    var libraryHasShownLanguageFilterAlert: DefaultsKey<Bool> { .
        init("libraryHasShownLanguageFilterAlert", defaultValue: false)
    }
    var libraryFilterLanguageCodes: DefaultsKey<[String]> { .init("libraryFilterLanguageCodes", defaultValue: []) }
    var libraryLanguageSortingMode: DefaultsKey<LibraryLanguageSortingMode> {
        .init("libraryLanguageSortingMode", defaultValue: LibraryLanguageSortingMode.alphabetically)
    }
}
