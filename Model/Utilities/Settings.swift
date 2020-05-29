//
//  Settings.swift
//  Kiwix
//
//  Created by Chris Li on 6/20/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import Defaults
import SwiftyUserDefaults

extension DefaultsKeys {
    static let recentSearchTexts = DefaultsKey<[String]>("recentSearchTexts", defaultValue: [])
    static let backupDocumentDirectory = DefaultsKey<Bool>("backupDocumentDirectory", defaultValue: false)
    static let webViewZoomScale = DefaultsKey<Double?>("webViewZoomScale")
    
    static let libraryLastRefreshTime = DefaultsKey<Date?>("libraryLastRefreshTime")
    static let libraryAutoRefresh = DefaultsKey<Bool>("libraryAutoRefresh", defaultValue: true)
}

extension Defaults.Keys {
    // reading
    static let externalLinkLoadingPolicy = Key<ExternalLinkLoadingPolicy>("externalLinkLoadingPolicy", default: .alwaysAsk)
    
    // UI
    static let sideBarDisplayMode = Key<SideBarDisplayMode>("sideBarDisplayMode", default: .automatic)
    
    // search
    static let recentSearchTexts = Key<[String]>("recentSearchTexts", default: [])
    static let searchResultSnippetMode = Key<SearchResultSnippetMode>("searchResultSnippetMode", default: .firstParagraph)
    
    // library
    static let libraryFilterLanguageCodes = Key<[String]>("libraryFilterLanguageCodes", default: [])
    static let libraryShownLanguageFilterAlert = Key<Bool>("libraryHasShownLanguageFilterAlert", default: false)
    static let libraryLanguageSortingMode = Key<LibraryLanguageFilterSortingMode>(
        "libraryLanguageSortingMode", default: LibraryLanguageFilterSortingMode.alphabetically
    )
}

extension Defaults {
    static subscript(key: Key<[String]>) -> [String] {
        get { (key.suite.array(forKey: key.name) as? [String]) ?? key.defaultValue }
        set { key.suite.set(newValue, forKey: key.name) }
    }
    
    static subscript(key: Key<ExternalLinkLoadingPolicy>) -> ExternalLinkLoadingPolicy {
        get { ExternalLinkLoadingPolicy(rawValue: key.suite.integer(forKey: key.name)) ?? key.defaultValue }
        set { key.suite.set(newValue.rawValue, forKey: key.name) }
    }
    
    static subscript(key: Key<SideBarDisplayMode>) -> SideBarDisplayMode {
        get { SideBarDisplayMode(rawValue: key.suite.string(forKey: key.name) ?? "") ?? key.defaultValue }
        set { key.suite.set(newValue.rawValue, forKey: key.name) }
    }
    
    static subscript(key: Key<SearchResultSnippetMode>) -> SearchResultSnippetMode {
        get {
            if let mode = SearchResultSnippetMode(rawValue: key.suite.string(forKey: key.name) ?? "") {
                return mode
            } else if key.suite.bool(forKey: "searchResultExcludeSnippet") {
                return .disabled
            } else {
                return .firstParagraph
            }
        }
        set { key.suite.set(newValue.rawValue, forKey: key.name) }
    }
    
    static subscript(key: Key<LibraryLanguageFilterSortingMode>) -> LibraryLanguageFilterSortingMode {
        get { LibraryLanguageFilterSortingMode(rawValue: key.suite.string(forKey: key.name) ?? "") ?? key.defaultValue }
        set { key.suite.set(newValue.rawValue, forKey: key.name) }
    }
}
