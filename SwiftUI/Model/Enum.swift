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

import CoreData
import MapKit

import Defaults

enum ActiveAlert: String, Identifiable {
    var id: String { rawValue }

    case articleFailedToLoad
    case downloadFailed
}

enum ActiveSheet: Hashable, Identifiable {
    var id: Int { hashValue }

    case outline
    case bookmarks
    case library(tabItem: LibraryTabItem? = nil)
    case map(location: CLLocation?)
    case settings
    case safari(url: URL)
}

enum Category: String, CaseIterable, Identifiable, LosslessStringConvertible {
    var description: String { rawValue }

    var id: String { rawValue }

    case wikipedia
    case wikibooks
    case wikinews
    case wikiquote
    case wikisource
    case wikiversity
    case wikivoyage
    case wiktionary
    case vikidia
    case ted
    case stackExchange = "stack_exchange"
    case other

    init?(_ description: String) {
        self.init(rawValue: description)
    }

    init?(rawValue: String?) {
        self.init(rawValue: rawValue ?? "other")
    }

    var name: String {
        switch self {
        case .wikipedia:
            return "enum.category.wikipedia".localized
        case .wikibooks:
            return "enum.category.wikibooks".localized
        case .wikinews:
            return "enum.category.wikinews".localized
        case .wikiquote:
            return "enum.category.wikiquote".localized
        case .wikisource:
            return "enum.category.wikisource".localized
        case .wikiversity:
            return "enum.category.wikiversity".localized
        case .wikivoyage:
            return "enum.category.wikivoyage".localized
        case .wiktionary:
            return "enum.category.wiktionary".localized
        case .ted:
            return "enum.category.ted".localized
        case .vikidia:
            return "enum.category.vikidia".localized
        case .stackExchange:
            return "enum.category.stackexchange".localized
        case .other:
            return "enum.category.other".localized
        }
    }

    var icon: String {
        switch self {
        case .wikipedia:
            return "Wikipedia"
        case .wikibooks:
            return "Wikibooks"
        case .wikinews:
            return "Wikinews"
        case .wikiquote:
            return "Wikiquote"
        case .wikisource:
            return "Wikisource"
        case .wikiversity:
            return "Wikiversity"
        case .wikivoyage:
            return "Wikivoyage"
        case .wiktionary:
            return "Wiktionary"
        case .ted:
            return "TED"
        case .vikidia:
            return "Vikidia"
        case .stackExchange:
            return "StackExchange"
        case .other:
            return "Other"
        }
    }
}

enum ExternalLinkLoadingPolicy: String, CaseIterable, Identifiable, Defaults.Serializable {
    case alwaysAsk, alwaysLoad, neverLoad

    var id: String { self.rawValue }

    var name: String {
        switch self {
        case .alwaysAsk:
            return "enum.external_link_loading_policy.always_ask".localized
        case .alwaysLoad:
            return "enum.external_link_loading_policy.always_load".localized
        case .neverLoad:
            return "enum.external_link_loading_policy.never_load".localized
        }
    }
}

enum OpenFileContext: String {
    case command
    case file
    case onBoarding
    case library
}

enum Flavor: String, CustomStringConvertible {
    case max = "maxi"
    case noPic = "nopic"
    case mini = "mini"

    init?(rawValue: String?) {
        self.init(rawValue: rawValue ?? "")
    }

    var description: String {
        switch self {
        case .max:
            return "enum.flavor.max".localized
        case .noPic:
            return "enum.flavor.no_pic".localized
        case .mini:
            return "enum.flavor.mini".localized
        }
    }
}

enum LibraryLanguageSortingMode: String, CaseIterable, Identifiable, Defaults.Serializable {
    case alphabetically, byCounts

    var id: String { self.rawValue }

    var name: String {
        switch self {
        case .alphabetically:
            return "enum.library_language_sorting_model.a-z".localized
        case .byCounts:
            return "enum.library_language_sorting_model.by_count".localized
        }
    }
}

enum LibraryTabItem: String, CaseIterable, Identifiable {
    case categories, new, downloads, opened

    var id: String { self.rawValue }

    var name: String {
        switch self {
        case .opened:
            return "enum.libray_tab_item.opened".localized
        case .categories:
            return "enum.libray_tab_item.categories".localized
        case .downloads:
            return "enum.libray_tab_item.downloads".localized
        case .new:
            return "enum.libray_tab_item.new".localized
        }
    }

    var icon: String {
        switch self {
        case .opened:
            return "folder"
        case .categories:
            return "books.vertical"
        case .downloads:
            return "tray.and.arrow.down"
        case .new:
            return "newspaper"
        }
    }
}

enum NavigationItem: Hashable, Identifiable {
    var id: Int { hashValue }

    case loading
    case bookmarks, map(location: CLLocation?), tab(objectID: NSManagedObjectID)
    case opened, categories, new, downloads
    case settings

    var name: String {
        switch self {
        case .loading:
            return "enum.navigation_item.loading".localized
        case .bookmarks:
            return "enum.navigation_item.bookmarks".localized
        case .map:
            return "enum.navigation_item.map".localized
        case .tab:
            #if os(macOS)
            return "enum.navigation_item.reading".localized
            #else
            return "enum.navigation_item.new_tab".localized
            #endif
        case .opened:
            return "enum.navigation_item.opened".localized
        case .categories:
            return "enum.navigation_item.categories".localized
        case .new:
            return "enum.navigation_item.new".localized
        case .downloads:
            return "enum.navigation_item.downloads".localized
        case .settings:
            return "enum.navigation_item.settings".localized
        }
    }

    var icon: String {
        switch self {
        case .loading:
            return "loading"
        case .bookmarks:
            return "star"
        case .map:
            return "map"
        case .tab:
            #if os(macOS)
            return "book"
            #else
            return "square"
            #endif
        case .opened:
            return "folder"
        case .categories:
            return "books.vertical"
        case .new:
            return "newspaper"
        case .downloads:
            return "tray.and.arrow.down"
        case .settings:
            return "gear"
        }
    }
}

/// Note: The cases were reduced from:
/// `case disabled, firstParagraph, firstSentence, matches`
/// which (due to enum values) accurately migrating our users, as of our intents
/// DO NOT change the order of the cases, as that might cause migration problems from version 3.4.0
/// see: https://github.com/kiwix/kiwix-apple/issues/853
enum SearchResultSnippetMode: String, CaseIterable, Identifiable, Defaults.Serializable {
    case disabled, matches

    var id: String { rawValue }

    var name: String {
        switch self {
        case .disabled:
            return "enum.search_result_snippet_mode.disabled".localized
        case .matches:
            return "enum.search_result_snippet_mode.matches".localized
        }
    }
}

enum SheetDisplayMode: String, Identifiable {
    case outline, bookmarks, library, settings

    var id: String { rawValue }
}
