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
