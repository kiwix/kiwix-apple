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
    static let libraryDownloadUsingCellular = Key<Bool>("libraryDownloadUsingCellular", default: false)
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
        if let value = getStringValue(key: "libraryLangucageSortingMode") {
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
            UserDefaults.standard.removeObject(forKey: "libraryFilterLanguageCodes")
        }
        if let value = Defaults[.libraryLastRefreshTime] {
            Defaults[.libraryLastRefresh] = value
            Defaults[.libraryLastRefreshTime] = nil
        }
    }
}

extension Defaults.Serializable where Self: Codable {
    public static var bridge: Defaults.TopLevelCodableBridge<Self> { Defaults.TopLevelCodableBridge() }
}

extension Defaults.Serializable where Self: Codable & NSSecureCoding {
    public static var bridge: Defaults.CodableNSSecureCodingBridge<Self> { Defaults.CodableNSSecureCodingBridge() }
}

extension Defaults.Serializable where Self: Codable & NSSecureCoding & Defaults.PreferNSSecureCoding {
    public static var bridge: Defaults.NSSecureCodingBridge<Self> { Defaults.NSSecureCodingBridge() }
}

extension Defaults.Serializable where Self: Codable & RawRepresentable {
    public static var bridge: Defaults.RawRepresentableCodableBridge<Self> { Defaults.RawRepresentableCodableBridge() }
}

extension Defaults.Serializable where Self: Codable & RawRepresentable & Defaults.PreferRawRepresentable {
    public static var bridge: Defaults.RawRepresentableBridge<Self> { Defaults.RawRepresentableBridge() }
}

extension Defaults.Serializable where Self: RawRepresentable {
    public static var bridge: Defaults.RawRepresentableBridge<Self> { Defaults.RawRepresentableBridge() }
}
extension Defaults.Serializable where Self: NSSecureCoding {
    public static var bridge: Defaults.NSSecureCodingBridge<Self> { Defaults.NSSecureCodingBridge() }
}

extension Defaults.CollectionSerializable where Element: Defaults.Serializable {
    public static var bridge: Defaults.CollectionBridge<Self> { Defaults.CollectionBridge() }
}

extension Defaults.SetAlgebraSerializable where Element: Defaults.Serializable & Hashable {
    public static var bridge: Defaults.SetAlgebraBridge<Self> { Defaults.SetAlgebraBridge() }
}
