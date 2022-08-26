//
//  Enum.swift
//  Kiwix
//
//  Created by Chris Li on 12/25/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Defaults

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
            return "Always ask"
        case .alwaysLoad:
            return "Always load"
        case .neverLoad:
            return "Never load"
        }
    }
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

enum NavigationItem: String, Identifiable, CaseIterable {
    var id: String { rawValue }

    case reading, bookmarks, map, opened, categories, new, downloads

    var name: String {
        switch self {
        case .reading:
            return "Reading"
        case .bookmarks:
            return "Bookmarks"
        case .map:
            return "Map"
        case .opened:
            return "Opened"
        case .categories:
            return "Categories"
        case .new:
            return "New"
        case .downloads:
            return "Downloads"
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
        case .opened:
            return "folder"
        case .categories:
            return "books.vertical"
        case .new:
            return "newspaper"
        case .downloads:
            return "tray.and.arrow.down"
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
