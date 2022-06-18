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

enum LibraryTopic: Hashable, Identifiable, RawRepresentable {
    case opened, new, downloads, categories
    case category(Category)
    
    init?(rawValue: String) {
        let parts = rawValue.split(separator: ".")
        switch parts.first {
        case "new":
            self = .new
        case "downloads":
            self = .downloads
        case "categories":
            self = .categories
        default:
            self = .opened
        }
    }
    
    var rawValue: String {
        switch self {
        case .opened:
            return "opened"
        case .new:
            return "new"
        case .downloads:
            return "downloads"
        case .categories:
            return "categories"
        case .category(let category):
            return "category.\(category.rawValue)"
        }
    }
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .opened:
            return "Opened"
        case .new:
            return "New"
        case .downloads:
            return "Downloads"
        case .categories:
            return "Categories"
        case .category(let category):
            return category.description
        }
    }
    
    var iconName: String {
        switch self {
        case .opened:
            return "folder"
        case .new:
            return "newspaper"
        case .downloads:
            return "tray.and.arrow.down"
        case .categories:
            return "books.vertical"
        case .category(_):
            return "book"
        }
    }
}

enum SearchResultSnippetMode: String, CaseIterable, Identifiable  {
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

enum SidebarDisplayMode: String, CaseIterable, Identifiable {
    case search, bookmarks, outline, library
    
    var id: String { rawValue }
    
    var imageName: String {
        switch self {
        case .search:
            return "magnifyingglass"
        case .bookmarks:
            return "star"
        case .outline:
            return "list.bullet"
        case .library:
            return "folder"
        }
    }
    
    var help: String {
        switch self {
        case .search:
            return "Search for articles"
        case .bookmarks:
            return "Show bookmarked articles"
        case .outline:
            return "Show article outline"
        case .library:
            return "Show opened zim files"
        }
    }
}
