//
//  Errors.swift
//  Kiwix
//
//  Created by Chris Li on 12/30/21.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import Foundation

public enum LibraryRefreshError: LocalizedError {
    case retrieve(description: String?)
    case parse
    case process

    public var errorDescription: String? {
        switch self {
        case .retrieve(let description):
            let prefix = "Error retrieving library data.".localized(withComment: "Library Refresh Error")
            return [prefix, description].compactMap({ $0 }).joined(separator: " ")
        case .parse:
            return "Error parsing library data.".localized(withComment: "Library Refresh Error")
        case .process:
            return "Error processing library data.".localized(withComment: "Library Refresh Error")
        }
    }
}
