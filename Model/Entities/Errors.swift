//
//  Errors.swift
//  Kiwix
//
//  Created by Chris Li on 12/30/21.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import Foundation

public enum LibraryRefreshError: LocalizedError {
    case retrieve(description: String)
    case parse
    case process

    public var errorDescription: String? {
        switch self {
        case .retrieve(let description):
            return [
                NSLocalizedString("Error retrieving library data.", comment: "Library Refresh Error"), description
            ].joined(separator: " ")
        case .parse:
            return NSLocalizedString("Library data parsing Error", comment: "")
        case .process:
            return NSLocalizedString("Library data processing error", comment: "")
        }
    }
}
