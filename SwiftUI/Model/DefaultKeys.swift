// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Defaults
import Foundation

extension Defaults.Keys {
//    // reading
    static let webViewTextSizeAdjustFactor = Key<Double>("webViewZoomScale", default: 1)
    static let webViewPageZoom = Key<Double>("webViewPageZoom", default: 1)
    static let externalLinkLoadingPolicy = Key<ExternalLinkLoadingPolicy>(
        "externalLinkLoadingPolicy", default: Brand.defaultExternalLinkPolicy
    )
    static let searchResultSnippetMode = Key<SearchResultSnippetMode>(
        "searchResultSnippetMode", default: Brand.defaultSearchSnippetMode
    )

    // search
    static let recentSearchTexts = Key<[String]>("recentSearchTexts", default: [])

    // library
    static let libraryLanguageCodes = Key<Set<String>>("libraryLanguageCodes", default: Set())
    static let libraryETag = Key<String>("libraryETag", default: "")
    static let libraryLanguageSortingMode = Key<LibraryLanguageSortingMode>(
        "libraryLanguageSortingMode", default: LibraryLanguageSortingMode.byCounts
    )
    static let libraryAutoRefresh = Key<Bool>("libraryAutoRefresh", default: true)
    static let libraryUsingOldISOLangCodes = Key<Bool>("libraryUsingOldISOLangCodes", default: true)
    static let libraryLastRefresh = Key<Date?>("libraryLastRefresh")

    static let isFirstLaunch = Key<Bool>("isFirstLaunch", default: true)
    static let downloadUsingCellular = Key<Bool>("downloadUsingCellular", default: false)
    static let backupDocumentDirectory = Key<Bool>("backupDocumentDirectory", default: false)

    static let categoriesToLanguages = Key<[Category: Set<String>]>("categoriesToLanguages", default: [:])
    static let hasSeenCategories = Key<Bool>("hasSeenCategories", default: false)

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
