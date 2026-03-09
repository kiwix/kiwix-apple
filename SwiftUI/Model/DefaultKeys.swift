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
    static let selectedCategory = Key<String?>("selectedCategory", default: nil)
    
    static let hotspotPortNumber = Key<Int>("hotspotPortNumber", default: Hotspot.defaultPort)

    #if os(macOS)
    // window management:
    static let windowURLs = Key<[URL]>("windowURLs", default: [])
    
    // downloads - custom directory for direct-write downloads on macOS
    // Stores security-scoped bookmark data to maintain access across app restarts
    static let downloadDirectoryBookmark = Key<Data?>("downloadDirectoryBookmark")
    #endif
}
