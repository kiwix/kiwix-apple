//
//  Settings.swift
//  Kiwix
//
//  Created by Chris Li on 6/20/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import SwiftyUserDefaults

extension DefaultsKeys {
    var recentSearchTexts: DefaultsKey<[String]> { .init("recentSearchTexts", defaultValue: []) }
    var backupDocumentDirectory: DefaultsKey<Bool> { .init("backupDocumentDirectory", defaultValue: false) }
    var webViewZoomScale: DefaultsKey<Double?> { .init("webViewZoomScale") }
    var externalLinkLoadingPolicy: DefaultsKey<Int> { .init("externalLinkLoadingPolicy", defaultValue: 0) }

    private var searchResultExcludeSnippet: DefaultsKey<Bool> { .init("searchResultExcludeSnippet", defaultValue: false) }
    var searchResultSnippetMode: DefaultsKey<String> { .init("searchResultSnippetMode", defaultValue: Defaults.searchResultExcludeSnippet ? SearchResultSnippetMode.disabled .rawValue : SearchResultSnippetMode.matches.rawValue) }
    
    var libraryAutoRefresh: DefaultsKey<Bool> { .init("libraryAutoRefresh", defaultValue: true) }
    var libraryLastRefreshTime: DefaultsKey<Date?> { .init("libraryLastRefreshTime") }
    var libraryHasShownLanguageFilterAlert: DefaultsKey<Bool> { .init("libraryHasShownLanguageFilterAlert", defaultValue: false) }
    var libraryFilterLanguageCodes: DefaultsKey<[String]> { .init("libraryFilterLanguageCodes", defaultValue: []) }
    var libraryLanguageSortingMode: DefaultsKey<String> { .init("libraryLanguageSortingMode", defaultValue: LibraryLanguageController.SortingMode.alphabetically.rawValue) }
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
