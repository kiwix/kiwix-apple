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

enum Category: String, CaseIterable, Identifiable, LosslessStringConvertible, Hashable {
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
            return LocalString.enum_category_wikipedia
        case .wikibooks:
            return LocalString.enum_category_wikibooks
        case .wikinews:
            return LocalString.enum_category_wikinews
        case .wikiquote:
            return LocalString.enum_category_wikiquote
        case .wikisource:
            return LocalString.enum_category_wikisource
        case .wikiversity:
            return LocalString.enum_category_wikiversity
        case .wikivoyage:
            return LocalString.enum_category_wikivoyage
        case .wiktionary:
            return LocalString.enum_category_wiktionary
        case .ted:
            return LocalString.enum_category_ted
        case .vikidia:
            return LocalString.enum_category_vikidia
        case .stackExchange:
            return LocalString.enum_category_stackexchange
        case .other:
            return LocalString.enum_category_other
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
            return LocalString.enum_external_link_loading_policy_always_ask
        case .alwaysLoad:
            return LocalString.enum_external_link_loading_policy_always_load
        case .neverLoad:
            return LocalString.enum_external_link_loading_policy_never_load
        }
    }
}

enum OpenURLContext: String {
    case deepLink
    case file
}

enum OpenFileContext: String {
    case command
    case file
    case welcomeScreen
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
            return LocalString.enum_flavor_max
        case .noPic:
            return LocalString.enum_flavor_no_pic
        case .mini:
            return LocalString.enum_flavor_mini
        }
    }
}

enum LibraryLanguageSortingMode: String, CaseIterable, Identifiable, Defaults.Serializable {
    case alphabetically, byCounts

    var id: String { self.rawValue }

    var name: String {
        switch self {
        case .alphabetically:
            return LocalString.enum_library_language_sorting_model_a_z
        case .byCounts:
            return LocalString.enum_library_language_sorting_model_by_count
        }
    }
}

enum LibraryTabItem: String, CaseIterable, Identifiable {
    case categories, new, downloads, opened

    var id: String { self.rawValue }

    var name: String {
        switch self {
        case .opened:
            return LocalString.enum_libray_tab_item_opened
        case .categories:
            return LocalString.enum_libray_tab_item_categories
        case .downloads:
            return LocalString.enum_libray_tab_item_downloads
        case .new:
            return LocalString.enum_libray_tab_item_new
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
}

enum MenuItem: Hashable {
    case tab(objectID: NSManagedObjectID)
    case bookmarks
    case opened
    case categories
    case new
    case downloads
    case settings
    case donation
    
    init?(from navigationItem: NavigationItem) {
        switch navigationItem {
        case .loading, .map: return nil
        case .bookmarks: self = .bookmarks
        case .tab(let objectID): self = .tab(objectID: objectID)
        case .opened: self = .opened
        case .categories: self = .categories
        case .new: self = .new
        case .downloads: self = .downloads
        case .settings: self = .settings
        }
    }
    
    var navigationItem: NavigationItem? {
        switch self {
        case .tab(objectID: let objectID): .tab(objectID: objectID)
        case .bookmarks: .bookmarks
        case .opened: .opened
        case .categories: .categories
        case .new: .new
        case .downloads: .downloads
        case .settings: .settings
        case .donation: nil
        }
    }
    
    var name: String {
        switch self {
        case .bookmarks:
            return LocalString.enum_navigation_item_bookmarks
        case .tab:
#if os(macOS)
            return LocalString.enum_navigation_item_reading
#else
            return LocalString.enum_navigation_item_new_tab
#endif
        case .opened:
            return LocalString.enum_navigation_item_opened
        case .categories:
            return LocalString.enum_navigation_item_categories
        case .new:
            return LocalString.enum_navigation_item_new
        case .downloads:
            return LocalString.enum_navigation_item_downloads
        case .settings:
            return LocalString.enum_navigation_item_settings
        case .donation:
            return LocalString.payment_support_button_label
        }
    }
    
    var icon: String {
        switch self {
        case .bookmarks:
            return "star"
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
        case .donation:
            return "heart.fill"
        }
    }
    var iconForegroundColor: UIColor? {
        switch self {
        case .donation:
            return UIColor.red
        case .tab, .bookmarks, .opened, .categories, .new, .downloads, .settings:
            return nil
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
            return LocalString.enum_search_result_snippet_mode_disabled
        case .matches:
            return LocalString.enum_search_result_snippet_mode_matches
        }
    }
}

enum SheetDisplayMode: String, Identifiable {
    case outline, bookmarks, library, settings

    var id: String { rawValue }
}
