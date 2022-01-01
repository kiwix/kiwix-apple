//
//  Enum.swift
//  Kiwix
//
//  Created by Chris Li on 12/25/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

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
    case ted
    case vikidia
    case stackExchange = "stack_exchange"
    case other
    
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
}

enum LibraryDisplayMode: CustomStringConvertible, Hashable {
    case opened, featured, new, downloads
    case category(Category)
    
    var description: String {
        switch self {
        case .opened:
            return "Opened"
        case .featured:
            return "Featured"
        case .new:
            return "New"
        case .downloads:
            return "Downloads"
        case .category(let category):
            return category.description
        }
    }
    
    var iconName: String {
        switch self {
        case .opened:
            return "laptopcomputer"
        case .featured:
            return "lightbulb"
        case .new:
            return "newspaper"
        case .downloads:
            return "square.and.arrow.down"
        case .category(_):
            return "book"
        }
    }
}

enum SidebarDisplayMode: String {
    case search, bookmark, tableOfContent, library
}
