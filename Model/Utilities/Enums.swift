//
//  Enums.swift
//  Kiwix
//
//  Created by Chris Li on 5/10/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftyUserDefaults

enum LibraryLanguageSortingMode: String, DefaultsSerializable {
    case alphabetically, byCount
    
    var localizedDescription: String {
        switch self {
        case .alphabetically:
            return NSLocalizedString("A-Z", comment: "Library: Language Filter Sorting")
        case .byCount:
            return NSLocalizedString("By Count", comment: "Library: Language Filter Sorting")
        }
    }
}

enum SearchResultSnippetMode: String, CustomStringConvertible, DefaultsSerializable {
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
