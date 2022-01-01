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

enum LibraryDisplayMode: CaseIterable, CustomStringConvertible, Hashable {
    static var allCases: [LibraryDisplayMode] = [.opened, .featured, .new] + Category.allCases.map {.category($0)}
    
    
    case opened, featured, new
    case category(Category)
    
    var description: String {
        switch self {
        case .opened:
            return "Opened"
        case .featured:
            return "Featured"
        case .new:
            return "New"
        case .category(let category):
            return category.description
        }
    }
}

enum SidebarDisplayMode: String {
    case search, bookmark, tableOfContent, library
}
