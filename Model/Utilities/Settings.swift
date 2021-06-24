//
//  Settings.swift
//  Kiwix
//
//  Created by Chris Li on 6/20/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import Defaults

extension Defaults.Keys {
    // reading
    static let externalLinkLoadingPolicy = Key<ExternalLinkLoadingPolicy>(
        "externalLinkLoadingPolicy", default: .alwaysAsk
    )
    static let webViewTextSizeAdjustFactor = Key<Double>("webViewZoomScale", default: 1)
    
    // UI
    static let sideBarDisplayMode = Key<SideBarDisplayMode>("sideBarDisplayMode", default: .automatic)
    
    // search
    static let recentSearchTexts = Key<[String]>("recentSearchTexts", default: [])
    static let searchResultSnippetMode = Key<SearchResultSnippetMode>(
        "searchResultSnippetMode", default: .firstSentence
    )
    
    // library
    static let libraryLanguageCodes = Key<[String]>("libraryLanguageCodes", default: [])
    static let libraryShownLanguageFilterAlert = Key<Bool>("libraryHasShownLanguageFilterAlert", default: false)
    static let libraryLanguageSortingMode = Key<LibraryLanguageSortingMode>(
        "libraryLanguageSortingMode", default: LibraryLanguageSortingMode.alphabetically
    )
    static let libraryAutoRefresh = Key<Bool>("libraryAutoRefresh", default: true)
    static let libraryLastRefresh = Key<Date?>("libraryLastRefresh")
    static let libraryLastRefreshTime = Key<Date?>("libraryLastRefreshTime")
    static let backupDocumentDirectory = Key<Bool>("backupDocumentDirectory", default: false)
}

extension Defaults {
    static func migrate() {
        func getStringValue(key: String) -> String? {
            guard let string = UserDefaults.standard.string(forKey: key),
                  let decoded = try? JSONDecoder().decode(String.self, from: Data(string.utf8)) else { return nil }
            return decoded
        }
        
        switch UserDefaults.standard.integer(forKey: "externalLinkLoadingPolicy") {
        case 1:
            UserDefaults.standard.setValue("alwaysLoad", forKeyPath: "externalLinkLoadingPolicy")
        case 2:
            UserDefaults.standard.setValue("neverLoad", forKeyPath: "externalLinkLoadingPolicy")
        default:
            UserDefaults.standard.setValue("alwaysAsk", forKeyPath: "externalLinkLoadingPolicy")
        }
        if let value = getStringValue(key: "libraryLanguageSortingMode") {
            UserDefaults.standard.setValue(value, forKeyPath: "libraryLanguageSortingMode")
        }
        if let value = getStringValue(key: "searchResultSnippetMode") {
            UserDefaults.standard.setValue(value, forKeyPath: "searchResultSnippetMode")
        }
        if let value = getStringValue(key: "sideBarDisplayMode") {
            UserDefaults.standard.setValue(value, forKeyPath: "sideBarDisplayMode")
        }
        if let value = UserDefaults.standard.stringArray(forKey: "libraryFilterLanguageCodes") {
            UserDefaults.standard.setValue(value, forKeyPath: "libraryLanguageCodes")
        }
        if let value = Defaults[.libraryLastRefreshTime] {
            Defaults[.libraryLastRefresh] = value
            Defaults[.libraryLastRefreshTime] = nil
        }
    }
}

extension UserDefaults {
    @objc var recentSearchTexts: [String] {
        get { stringArray(forKey: "recentSearchTexts") ?? [] }
        set { setValue(newValue, forKey: "recentSearchTexts") }
    }
    
    @objc var libraryLanguageCodes: [String] {
        get { stringArray(forKey: "libraryFilterLanguageCodes") ?? [] }
        set { setValue(newValue, forKey: "libraryFilterLanguageCodes") }
    }
}
