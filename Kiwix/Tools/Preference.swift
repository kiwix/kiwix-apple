//
//  Preference.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import SwiftyUserDefaults

class Preference {
    
    class var hasShowGetStartedAlert: Bool {
        get{return Defaults[.hasShowGetStartedAlert]}
        set{Defaults[.hasShowGetStartedAlert] = newValue}
    }
    
    // MARK: - Recent Search
    
    class func addRecentSearchTerm(searchTerm: String) {
        recentSearchTerms.insert(searchTerm, atIndex: 0)
    }
    
    class var recentSearchTerms: [String] {
        get{return Defaults[.recentSearchTerms]}
        set{
            let searchTerms = NSOrderedSet(array: newValue).array as! [String]
            Defaults[.recentSearchTerms] = searchTerms.count > 20 ? Array(searchTerms[0..<20]) : searchTerms
        }
    }
    
    // MARK: - Reading
    
    class var webViewZoomScale: Double {
        get{return Defaults[.webViewZoomScale] ?? 100.0}
        set{Defaults[.webViewZoomScale] = newValue}
    }
    
    class var webViewInjectJavascriptToAdjustPageLayout: Bool {
        get{return !Defaults[.webViewNotInjectJavascriptToAdjustPageLayout]}
        set{Defaults[.webViewNotInjectJavascriptToAdjustPageLayout] = !newValue}
    }
    
    // MARK: - Rate Kiwix
    
    class var activeUseHistory: [NSDate] {
        get{return Defaults[.activeUseHistory]}
        set{Defaults[.activeUseHistory] = newValue}
    }
    
    class var haveRateKiwix: Bool {
        get{return Defaults[.haveRateKiwix]}
        set{Defaults[.haveRateKiwix] = newValue}
    }
    
    // MARK: - Library
    
    class var libraryAutoRefreshDisabled: Bool {
        get{return Defaults[.libraryAutoRefreshDisabled]}
        set{Defaults[.libraryAutoRefreshDisabled] = newValue}
    }
    
    class var libraryRefreshAllowCellularData: Bool {
        get{return !Defaults[.libraryRefreshNotAllowCellularData]}
        set{Defaults[.libraryRefreshNotAllowCellularData] = !newValue}
    }
    
    class var libraryLastRefreshTime: NSDate? {
        get{return Defaults[.libraryLastRefreshTime]}
        set{Defaults[.libraryLastRefreshTime] = newValue}
    }
    
    class var libraryRefreshInterval: NSTimeInterval {
        get{return Defaults[.libraryRefreshInterval] ?? 3600.0 * 24}
        set{Defaults[.libraryRefreshInterval] = newValue}
    }
    
    class var libraryHasShownPreferredLanguagePrompt: Bool {
        get{return Defaults[.libraryHasShownPreferredLanguagePrompt]}
        set{Defaults[.libraryHasShownPreferredLanguagePrompt] = newValue}
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
    
    class var resumeData: [String: NSData] {
        get{return Defaults[.resumeData] as? [String: NSData] ?? [String: NSData]()}
        set{Defaults[.resumeData] = newValue}}
}

extension DefaultsKeys {
    static let hasShowGetStartedAlert = DefaultsKey<Bool>("hasShowGetStartedAlert")
    static let recentSearchTerms = DefaultsKey<[String]>("recentSearchTerms")
    static let webViewZoomScale = DefaultsKey<Double?>("webViewZoomScale")
    static let webViewNotInjectJavascriptToAdjustPageLayout = DefaultsKey<Bool>("webViewNotInjectJavascriptToAdjustPageLayout")
    static let activeUseHistory = DefaultsKey<[NSDate]>("activeUseHistory")
    static let haveRateKiwix = DefaultsKey<Bool>("haveRateKiwix")
    
    static let libraryAutoRefreshDisabled = DefaultsKey<Bool>("libraryAutoRefreshDisabled")
    static let libraryRefreshNotAllowCellularData = DefaultsKey<Bool>("libraryRefreshNotAllowCellularData")
    static let libraryLastRefreshTime = DefaultsKey<NSDate?>("libraryLastRefreshTime")
    static let libraryRefreshInterval = DefaultsKey<Double?>("libraryRefreshInterval")
    static let libraryHasShownPreferredLanguagePrompt = DefaultsKey<Bool>("libraryHasShownPreferredLanguagePrompt")
    static let langFilterSortByAlphabeticalAsc = DefaultsKey<Bool>("langFilterSortByAlphabeticalAsc")
    static let langFilterNameDisplayInOriginalLocale = DefaultsKey<Bool>("langFilterNameDisplayInOriginalLocale")
    
    static let resumeData = DefaultsKey<[String: AnyObject]>("resumeData")
}
