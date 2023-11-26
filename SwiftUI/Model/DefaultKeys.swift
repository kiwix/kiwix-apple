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
    static let webViewTextSizeAdjustFactor = Key<Double>("webViewZoomScale", default: 1)
    static let webViewPageZoom = Key<Double>("webViewPageZoom", default: 1)
    static let externalLinkLoadingPolicy = Key<ExternalLinkLoadingPolicy>(
        "externalLinkLoadingPolicy", default: Brand.defaultExternalLinkPolicy
    )
    static let searchResultSnippetMode = Key<SearchResultSnippetMode>(
        "searchResultSnippetMode", default: .firstSentence
    )
//
//    // UI
//    static let sideBarDisplayMode = Key<SideBarDisplayMode>("sideBarDisplayMode", default: .automatic)
//
//    // search
    static let recentSearchTexts = Key<[String]>("recentSearchTexts", default: [])

    // library
    static let libraryLanguageCodes = Key<Set<String>>("libraryLanguageCodes", default: Set())
    static let libraryLanguageSortingMode = Key<LibraryLanguageSortingMode>(
        "libraryLanguageSortingMode", default: LibraryLanguageSortingMode.byCounts
    )
    static let libraryAutoRefresh = Key<Bool>("libraryAutoRefresh", default: true)
    static let libraryLastRefresh = Key<Date?>("libraryLastRefresh")
    static let libraryLastRefreshTime = Key<Date?>("libraryLastRefreshTime")
    
    static let downloadUsingCellular = Key<Bool>("downloadUsingCellular", default: false)
    static let backupDocumentDirectory = Key<Bool>("backupDocumentDirectory", default: false)

    #if os(macOS)
    // window management:
    static let windowURLs = Key<[URL]>("windowURLs", default: [])
    #endif
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
