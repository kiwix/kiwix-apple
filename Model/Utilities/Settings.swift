//
//  Settings.swift
//  Kiwix
//
//  Created by Chris Li on 6/20/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import SwiftyUserDefaults

extension DefaultsKeys {
    static let recentSearchTexts = DefaultsKey<[String]>("recentSearchTexts", defaultValue: [])
    static let backupDocumentDirectory = DefaultsKey<Bool>("backupDocumentDirectory", defaultValue: false)
    static let webViewZoomScale = DefaultsKey<Double?>("webViewZoomScale")
    static let externalLinkLoadingPolicy = DefaultsKey<Int>("externalLinkLoadingPolicy", defaultValue: 0)
    
    static let searchResultExcludeSnippet = DefaultsKey<Bool>("searchResultExcludeSnippet", defaultValue: false)
    static let searchResultSnippetMode = DefaultsKey<String>(
        "searchResultSnippetMode", defaultValue: Defaults[.searchResultExcludeSnippet]
            ? SearchResultSnippetMode.disabled .rawValue : SearchResultSnippetMode.matches.rawValue
    )
    
    static let libraryLastRefreshTime = DefaultsKey<Date?>("libraryLastRefreshTime")
    static let libraryHasShownLanguageFilterAlert = DefaultsKey<Bool>("libraryHasShownLanguageFilterAlert", defaultValue: false)
    static let libraryLanguageSortingMode = DefaultsKey<String>("libraryLanguageSortingMode", defaultValue: LibraryLanguageController.SortingMode.alphabetically.rawValue)
    static let libraryFilterLanguageCodes = DefaultsKey<[String]>("libraryFilterLanguageCodes", defaultValue: [])
    static let libraryAutoRefresh = DefaultsKey<Bool>("libraryAutoRefresh", defaultValue: true)
}

class Preference {
    
    // MARK: - Library
    
//    class var libraryAutoRefreshDisabled: Bool {
//        get{return Defaults[.libraryAutoRefreshDisabled]}
//        set{Defaults[.libraryAutoRefreshDisabled] = newValue}
//    }
//
//    class var libraryRefreshAllowCellularData: Bool {
//        get{return !Defaults[.libraryRefreshNotAllowCellularData]}
//        set{Defaults[.libraryRefreshNotAllowCellularData] = !newValue}
//    }
//
//    class var libraryRefreshInterval: TimeInterval {
//        get{return Defaults[.libraryRefreshInterval] ?? 3600.0 * 24}
//        set{Defaults[.libraryRefreshInterval] = newValue}
//    }
}

extension DefaultsKeys {
//    static let hasSubscribedToCloudKitChanges = DefaultsKey<Bool>("hasSubscribedToCloudKitChanges")
//    static let activeUseHistory = DefaultsKey<[Date]>("activeUseHistory")
//    static let haveRateKiwix = DefaultsKey<Bool>("haveRateKiwix")
//
//
//    static let libraryAutoRefreshDisabled = DefaultsKey<Bool>("libraryAutoRefreshDisabled")
//    static let libraryRefreshNotAllowCellularData = DefaultsKey<Bool>("libraryRefreshNotAllowCellularData")
//    static let libraryLastRefreshTime = DefaultsKey<Date?>("libraryLastRefreshTime")
//    static let libraryHasShownLanguageFilterAlert = DefaultsKey<Bool>("libraryHasShownLanguageFilterAlert")
//    static let libraryRefreshInterval = DefaultsKey<Double?>("libraryRefreshInterval")
}

// MARK: - Rate

extension Preference {
//    class Rate {
//        private static var activeHistoryKey = "Rate.activeHistory-\(Bundle.appShortVersion)"
//        private static var hasRatedKey = "Rate.hasRated-\(Bundle.appShortVersion)"
//        class var activeHistory: [Date] {
//            get {return UserDefaults.standard.array(forKey: activeHistoryKey)?.flatMap({$0 as? Date}) ?? [Date]()}
//            set {UserDefaults.standard.set(newValue, forKey: activeHistoryKey)}
//        }
//
//        class var hasRated: Bool {
//            get {return UserDefaults.standard.bool(forKey: hasRatedKey)}
//            set {UserDefaults.standard.set(newValue, forKey: hasRatedKey)}
//        }
//    }
}

// MARK: - Notifications

//extension Preference {
//    class Notifications {
//        class var libraryRefresh: Bool {
//            get{return Defaults[.notificationLibraryRefresh] ?? true}
//            set{Defaults[.notificationLibraryRefresh] = newValue}
//        }
//        class var bookUpdateAvailable: Bool {
//            get{return Defaults[.notificationBookUpdateAvailable] ?? true}
//            set{Defaults[.notificationBookUpdateAvailable] = newValue}
//        }
//        
//        class var bookDownloadFinish: Bool {
//            get{return Defaults[.notificationBookDownloadFinish] ?? true}
//            set{Defaults[.notificationBookDownloadFinish] = newValue}
//        }
//    }
//}
//
//extension DefaultsKeys {
//    static let notificationLibraryRefresh = DefaultsKey<Bool?>("notificationLibraryRefresh")
//    static let notificationBookUpdateAvailable = DefaultsKey<Bool?>("notificationBookUpdateAvailable")
//    static let notificationBookDownloadFinish = DefaultsKey<Bool?>("notificationBookDownloadFinish")
//}
