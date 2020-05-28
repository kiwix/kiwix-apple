//
//  Enums.swift
//  Kiwix
//
//  Created by Chris Li on 5/10/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

enum ExternalLinkLoadingPolicy: Int, Codable, CustomStringConvertible {
    case alwaysAsk = 0, alwaysLoad, neverLoad
    
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

enum SearchResultSnippetMode: String, Codable, CustomStringConvertible {
    case disabled, firstParagraph, firstSentence, matches
    
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

enum SideBarDisplayMode: String, Codable, CustomStringConvertible {
    case automatic, sideBySide, overlay
    
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
