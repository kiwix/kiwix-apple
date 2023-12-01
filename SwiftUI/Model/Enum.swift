//
//  Enum.swift
//  Kiwix
//
//  Created by Chris Li on 12/25/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData
import MapKit

import Defaults

enum ActiveAlert: String, Identifiable {
    var id: String { rawValue }
    
    case articleFailedToLoad
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

enum Category: String, CaseIterable, Identifiable {
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
    
    init?(rawValue: String?) {
        self.init(rawValue: rawValue ?? "")
    }
    
    var name: String {
        switch self {
        case .wikipedia:
            return "title-wikipedia".localized
        case .wikibooks:
            return "title-wikibooks".localized
        case .wikinews:
            return "title-wikinews".localized
        case .wikiquote:
            return "title-wikiquote".localized
        case .wikisource:
            return "title-wikisource".localized
        case .wikiversity:
            return "title-wikiversity".localized
        case .wikivoyage:
            return "title-wikivoyage".localized
        case .wiktionary:
            return "title-wiktionary".localized
        case .ted:
            return "title-ted".localized
        case .vikidia:
            return "title-vikidia".localized
        case .stackExchange:
            return "title-stackexchange".localized
        case .other:
            return "title-other".localized
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
            return "title-always-ask".localized
        case .alwaysLoad:
            return "title-always-load".localized
        case .neverLoad:
            return "title-never-load".localized
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
            return "title-max".localized
        case .noPic:
            return "title-no-pic".localized
        case .mini:
            return "title-mini".localized
        }
    }
}

enum LibraryLanguageSortingMode: String, CaseIterable, Identifiable, Defaults.Serializable {
    case alphabetically, byCounts
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .alphabetically:
            return "title-a-z".localized
        case .byCounts:
            return "title_by_country".localized
        }
    }
}

enum LibraryTabItem: String, CaseIterable, Identifiable {
    case opened, categories, downloads, new
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .opened:
            return "title-opened".localized
        case .categories:
            return "title-categories".localized
        case .downloads:
            return "title-downloads".localized
        case .new:
            return "title-new".localized
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
    case reading, bookmarks, map(location: CLLocation?), tab(objectID: NSManagedObjectID)
    case opened, categories, new, downloads
    case settings

    var name: String {
        switch self {
        case .loading:
            return "Loading"
        case .reading:
            return "title_reading".localized
        case .bookmarks:
            return "title-bookmarks".localized
        case .map:
            return "title-map".localized
        case .tab:
            return "title-tab-new".localized
        case .opened:
            return "title-opened".localized
        case .categories:
            return "title-categories".localized
        case .new:
            return "title-new".localized
        case .downloads:
            return "title-downloads".localized
        case .settings:
            return "button-tab-settings".localized
        }
    }
    
    var icon: String {
        switch self {
        case .loading:
            return "loading"
        case .reading:
            return "book"
        case .bookmarks:
            return "star"
        case .map:
            return "map"
        case .tab:
            return "square"
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

enum SearchResultSnippetMode: String, CaseIterable, Identifiable, Defaults.Serializable {
    case disabled, firstParagraph, firstSentence, matches
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .disabled:
            return "title-disabled".localized
        case .firstParagraph:
            return "title-first-paragraph".localized
        case .firstSentence:
            return "title-first-sentence".localized
        case .matches:
            return "title-matches".localized
        }
    }
}

enum SheetDisplayMode: String, Identifiable {
    case outline, bookmarks, library, settings
    
    var id: String { rawValue }
}
