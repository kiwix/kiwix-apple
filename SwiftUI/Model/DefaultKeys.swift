//
//  DefaultKeys.swift
//  Kiwix
//
//  Created by Chris Li on 6/16/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import Defaults

extension Defaults.Keys {
//    // reading
//    static let externalLinkLoadingPolicy = Key<ExternalLinkLoadingPolicy>(
//        "externalLinkLoadingPolicy", default: .alwaysAsk
//    )
//    static let webViewTextSizeAdjustFactor = Key<Double>("webViewZoomScale", default: 1)
//
//    // UI
//    static let sideBarDisplayMode = Key<SideBarDisplayMode>("sideBarDisplayMode", default: .automatic)
//
//    // search
//    static let recentSearchTexts = Key<[String]>("recentSearchTexts", default: [])
//    static let searchResultSnippetMode = Key<SearchResultSnippetMode>(
//        "searchResultSnippetMode", default: .firstSentence
//    )
    
    // library
    static let libraryLanguageCodes = Key<Set<String>>("libraryLanguageCodes", default: Set())
    static let libraryShownLanguageFilterAlert = Key<Bool>("libraryHasShownLanguageFilterAlert", default: false)
//    static let libraryLanguageSortingMode = Key<LibraryLanguageSortingMode>(
//        "libraryLanguageSortingMode", default: LibraryLanguageSortingMode.alphabetically
//    )
    static let libraryAutoRefresh = Key<Bool>("libraryAutoRefresh", default: true)
    static let libraryLastRefresh = Key<Date?>("libraryLastRefresh")
    static let libraryLastRefreshTime = Key<Date?>("libraryLastRefreshTime")
    static let libraryDownloadUsingCellular = Key<Bool>("libraryDownloadUsingCellular", default: false)
    static let backupDocumentDirectory = Key<Bool>("backupDocumentDirectory", default: false)
}
