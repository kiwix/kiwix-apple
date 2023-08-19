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
    
    var description: String {
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
    
    var name: String {
        description
    }
}

enum ExternalLinkLoadingPolicy: String, CaseIterable, Identifiable, Defaults.Serializable {
    case alwaysAsk, alwaysLoad, neverLoad
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .alwaysAsk:
            return "Always Ask"
        case .alwaysLoad:
            return "Always Load"
        case .neverLoad:
            return "Never Load"
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
            return "max"
        case .noPic:
            return "no pic"
        case .mini:
            return "mini"
        }
    }
}

enum LibraryLanguageSortingMode: String, CaseIterable, Identifiable, Defaults.Serializable {
    case alphabetically, byCounts
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .alphabetically:
            return "A-Z"
        case .byCounts:
            return "By Count"
        }
    }
}

enum LibraryTabItem: String, CaseIterable, Identifiable {
    case opened, categories, downloads, new
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .opened:
            return "Opened"
        case .categories:
            return "Categories"
        case .downloads:
            return "Downloads"
        case .new:
            return "New"
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

    case reading, bookmarks, map(location: CLLocation?), tab(objectID: NSManagedObjectID)
    case opened, categories, new, downloads
    case settings

    var name: String {
        switch self {
        case .reading:
            return "Reading"
        case .bookmarks:
            return "Bookmarks"
        case .map:
            return "Map"
        case .tab:
            return "New Tab"
        case .opened:
            return "Opened"
        case .categories:
            return "Categories"
        case .new:
            return "New"
        case .downloads:
            return "Downloads"
        case .settings:
            return "Settings"
        }
    }
    
    var icon: String {
        switch self {
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


enum SearchResultSnippetMode: String, CaseIterable, Identifiable, Defaults.Serializable  {
    case disabled, firstParagraph, firstSentence, matches
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .disabled:
            return "Disabled"
        case .firstParagraph:
            return "First Paragraph"
        case .firstSentence:
            return "First Sentence"
        case .matches:
            return "Matches"
        }
    }
}

enum SheetDisplayMode: String, Identifiable {
    case outline, bookmarks, library, settings
    
    var id: String { rawValue }
}
