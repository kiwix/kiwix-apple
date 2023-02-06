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
            let prefix = NSLocalizedString("Error retrieving library data.", comment: "Library Refresh Error")
            return [prefix, description].compactMap({ $0 }).joined(separator: " ")
        case .parse:
            return NSLocalizedString("Error parsing library data.", comment: "Library Refresh Error")
        case .process:
            return NSLocalizedString("Error processing library data.", comment: "Library Refresh Error")
        }
    }
}
