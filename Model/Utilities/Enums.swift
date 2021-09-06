//
//  Enums.swift
//  Kiwix
//
//  Created by Chris Li on 5/10/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Defaults

enum ExternalLinkLoadingPolicy: String, CaseIterable, CustomStringConvertible, Identifiable, Defaults.Serializable {
    case alwaysAsk, alwaysLoad, neverLoad
    
    var id: String { self.rawValue }
    var description: String {
        switch self {
        case .alwaysAsk:
            return NSLocalizedString("Always ask", comment: "External Link Loading Policy")
        case .alwaysLoad:
            return NSLocalizedString("Always load without asking", comment: "External Link Loading Policy")
        case .neverLoad:
            return NSLocalizedString("Never load and don't ask", comment: "External Link Loading Policy")
        }
    }
}

enum LibraryLanguageSortingMode: String, CaseIterable, Codable, CustomStringConvertible, Identifiable, Defaults.Serializable {
    case alphabetically, byCount
    
    var id: String { self.rawValue }
    var description: String {
        switch self {
        case .alphabetically:
            return NSLocalizedString("A-Z", comment: "Library: Language Filter Sorting")
        case .byCount:
            return NSLocalizedString("By Count", comment: "Library: Language Filter Sorting")
        }
    }
}

enum SearchResultSnippetMode: String, CaseIterable, CustomStringConvertible, Identifiable, Defaults.Serializable {
    case disabled, firstParagraph, firstSentence, matches
    
    var id: String { self.rawValue }
    var description: String {
        switch self {
        case .disabled:
            return NSLocalizedString("Disabled", comment: "Search Result Snippet Mode")
        case .firstParagraph:
            return NSLocalizedString("First Paragraph", comment: "Search Result Snippet Mode")
        case .firstSentence:
            return NSLocalizedString("First Sentence", comment: "Search Result Snippet Mode")
        case .matches:
            return NSLocalizedString("Matches", comment: "Search Result Snippet Mode")
        }
    }
}

enum SideBarDisplayMode: String, CaseIterable, CustomStringConvertible, Identifiable, Defaults.Serializable {
    case automatic, sideBySide, overlay
    
    var id: String { self.rawValue }
    var description: String {
        switch self {
        case .automatic:
            return NSLocalizedString("Automatic", comment: "Side Bar Display Mode")
        case .sideBySide:
            return NSLocalizedString("Side by Side", comment: "Side Bar Display Mode")
        case .overlay:
            return NSLocalizedString("Overlay", comment: "Side Bar Display Mode")
        }
    }
}
