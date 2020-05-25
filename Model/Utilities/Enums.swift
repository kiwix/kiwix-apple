//
//  Enums.swift
//  Kiwix
//
//  Created by Chris Li on 5/10/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

enum SearchResultSnippetMode: String, CustomStringConvertible {
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

enum SideBarDisplayMode: String, CustomStringConvertible {
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
