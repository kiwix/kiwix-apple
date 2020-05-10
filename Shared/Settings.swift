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
    static let searchResultSnippetExtractionMode = DefaultsKey<String>(
        "searchResultSnippetExtractionMode", defaultValue: SearchOperation.SnippetExtractionMode.matches.rawValue
    )
    
    static let libraryLastRefreshTime = DefaultsKey<Date?>("libraryLastRefreshTime")
    static let libraryHasShownLanguageFilterAlert = DefaultsKey<Bool>("libraryHasShownLanguageFilterAlert", defaultValue: false)
    static let libraryLanguageSortingMode = DefaultsKey<String>("libraryLanguageSortingMode", defaultValue: LibraryLanguageController.SortingMode.alphabetically.rawValue)
    static let libraryFilterLanguageCodes = DefaultsKey<[String]>("libraryFilterLanguageCodes", defaultValue: [])
    static let libraryAutoRefresh = DefaultsKey<Bool>("libraryAutoRefresh", defaultValue: true)
}
