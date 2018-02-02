//
//  Preference.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import SwiftyUserDefaults

class Preference {
    
    class var hasShowGetStartedAlert: Bool {
        get{return Defaults[.hasShowGetStartedAlert]}
        set{Defaults[.hasShowGetStartedAlert] = newValue}
    }
    
    class var hasSubscribedToCloudKitChanges: Bool {
        get{return Defaults[.hasSubscribedToCloudKitChanges]}
        set{Defaults[.hasSubscribedToCloudKitChanges] = newValue}
    }
    
    // MARK: - Recent Search
    
    class RecentSearch {
        class func add(term: String) {
            terms.insert(term, at: 0)
        }
        
        class var terms: [String] {
            get{return Defaults[.recentSearchTerms]}
            set{
                let searchTerms = NSOrderedSet(array: newValue).array as! [String]
                Defaults[.recentSearchTerms] = searchTerms.count > 20 ? Array(searchTerms[0..<20]) : searchTerms
            }
        }
    }
    
    // MARK: - Reading
    
//    class var webViewZoomScale: Double {
//        get{if let scale = Defaults[.webViewZoomScale] {return scale > 50 ? scale / 100 : scale} else {return 1}}
//        set{Defaults[.webViewZoomScale] = newValue}
//    }
    
    // MARK: - Library
    
    class var libraryAutoRefreshDisabled: Bool {
        get{return Defaults[.libraryAutoRefreshDisabled]}
        set{Defaults[.libraryAutoRefreshDisabled] = newValue}
    }
    
    class var libraryRefreshAllowCellularData: Bool {
        get{return !Defaults[.libraryRefreshNotAllowCellularData]}
        set{Defaults[.libraryRefreshNotAllowCellularData] = !newValue}
    }
    
    class var libraryLastRefreshTime: Date? {
        get{return Defaults[.libraryLastRefreshTime]}
        set{Defaults[.libraryLastRefreshTime] = newValue}
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
    
    // MARK: - Resume Data
    
    class var resumeData: [String: Data] {
        get{return Defaults[DefaultsKeys.resumeData] as? [String: Data] ?? [String: Data]()}
        set{Defaults[DefaultsKeys.resumeData] = newValue}}
}

extension DefaultsKeys {
    static let hasShowGetStartedAlert = DefaultsKey<Bool>("hasShowGetStartedAlert")
    static let hasSubscribedToCloudKitChanges = DefaultsKey<Bool>("hasSubscribedToCloudKitChanges")
    static let recentSearchTexts = DefaultsKey<[String]>("recentSearchTexts")
    static let recentSearchTerms = DefaultsKey<[String]>("recentSearchTerms")
    static let webViewZoomScale = DefaultsKey<Double?>("webViewZoomScale")
    static let activeUseHistory = DefaultsKey<[Date]>("activeUseHistory")
    static let haveRateKiwix = DefaultsKey<Bool>("haveRateKiwix")
    
    static let libraryAutoRefreshDisabled = DefaultsKey<Bool>("libraryAutoRefreshDisabled")
    static let libraryRefreshNotAllowCellularData = DefaultsKey<Bool>("libraryRefreshNotAllowCellularData")
    static let libraryLastRefreshTime = DefaultsKey<Date?>("libraryLastRefreshTime")
    static let libraryHasShownLanguageFilterAlert = DefaultsKey<Bool>("libraryHasShownLanguageFilterAlert")
    static let libraryRefreshInterval = DefaultsKey<Double?>("libraryRefreshInterval")
    static let langFilterSortByAlphabeticalAsc = DefaultsKey<Bool>("langFilterSortByAlphabeticalAsc")
    static let langFilterNameDisplayInOriginalLocale = DefaultsKey<Bool>("langFilterNameDisplayInOriginalLocale")
    
    static let resumeData = DefaultsKey<[String: Any]>("resumeData")
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
