//
//  Preference.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import SwiftyUserDefaults

class Preference {
    
    // MARK: - Library
    
    class var libraryAutoRefreshDisabled: Bool {
        get{return Defaults[.libraryAutoRefreshDisabled]}
        set{Defaults[.libraryAutoRefreshDisabled] = newValue}
    }
    
    class var libraryRefreshAllowCellularData: Bool {
        get{return !Defaults[.libraryRefreshNotAllowCellularData]}
        set{Defaults[.libraryRefreshNotAllowCellularData] = !newValue}
    }
    
    class var libraryRefreshInterval: TimeInterval {
        get{return Defaults[.libraryRefreshInterval] ?? 3600.0 * 24}
        set{Defaults[.libraryRefreshInterval] = newValue}
    }
    
    class LangFilter {
        class var sortByAlphabeticalAsc: Bool {
            get{return Defaults[.langFilterSortByAlphabeticalAsc]}
            set{Defaults[.langFilterSortByAlphabeticalAsc] = newValue}
        }
        
        class var displayInOriginalLocale: Bool {
            get{return Defaults[.langFilterNameDisplayInOriginalLocale]}
            set{Defaults[.langFilterNameDisplayInOriginalLocale] = newValue}
        }
    }
}

extension DefaultsKeys {
    static let hasSubscribedToCloudKitChanges = DefaultsKey<Bool>("hasSubscribedToCloudKitChanges")
    static let activeUseHistory = DefaultsKey<[Date]>("activeUseHistory")
    static let haveRateKiwix = DefaultsKey<Bool>("haveRateKiwix")
    
    
    static let recentSearchTexts = DefaultsKey<[String]>("recentSearchTexts")
    
    static let webViewZoomScale = DefaultsKey<Double?>("webViewZoomScale")
    static let backupDocumentDirectory = DefaultsKey<Bool>("backupDocumentDirectory")
    static let externalLinkLoadingPolicy = DefaultsKey<Int>("externalLinkLoadingPolicy")
    
    static let libraryAutoRefreshDisabled = DefaultsKey<Bool>("libraryAutoRefreshDisabled")
    static let libraryRefreshNotAllowCellularData = DefaultsKey<Bool>("libraryRefreshNotAllowCellularData")
    static let libraryLastRefreshTime = DefaultsKey<Date?>("libraryLastRefreshTime")
    static let libraryHasShownLanguageFilterAlert = DefaultsKey<Bool>("libraryHasShownLanguageFilterAlert")
    static let libraryRefreshInterval = DefaultsKey<Double?>("libraryRefreshInterval")
    static let libraryFilterLanguageCodes = DefaultsKey<[String]>("libraryFilterLanguageCodes")
    
    static let langFilterSortByAlphabeticalAsc = DefaultsKey<Bool>("langFilterSortByAlphabeticalAsc")
    static let langFilterNameDisplayInOriginalLocale = DefaultsKey<Bool>("langFilterNameDisplayInOriginalLocale")
    
    
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

extension Preference {
    class Notifications {
        class var libraryRefresh: Bool {
            get{return Defaults[.notificationLibraryRefresh] ?? true}
            set{Defaults[.notificationLibraryRefresh] = newValue}
        }
        class var bookUpdateAvailable: Bool {
            get{return Defaults[.notificationBookUpdateAvailable] ?? true}
            set{Defaults[.notificationBookUpdateAvailable] = newValue}
        }
        
        class var bookDownloadFinish: Bool {
            get{return Defaults[.notificationBookDownloadFinish] ?? true}
            set{Defaults[.notificationBookDownloadFinish] = newValue}
        }
    }
}

extension DefaultsKeys {
    static let notificationLibraryRefresh = DefaultsKey<Bool?>("notificationLibraryRefresh")
    static let notificationBookUpdateAvailable = DefaultsKey<Bool?>("notificationBookUpdateAvailable")
    static let notificationBookDownloadFinish = DefaultsKey<Bool?>("notificationBookDownloadFinish")
}
