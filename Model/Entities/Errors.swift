//
//  Errors.swift
//  Kiwix
//
//  Created by Chris Li on 12/30/21.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import Foundation

enum LibraryRefreshError: LocalizedError {
    case retrieve(description: String? = nil)
    case parse
    case process

    var errorDescription: String? {
        switch self {
        case .retrieve(let description):
            return description ?? NSLocalizedString("Error retrieving online catalog.", comment: "")
        case .parse:
            return NSLocalizedString("Library data parsing Error", comment: "")
        case .process:
            return NSLocalizedString("Library data processing error", comment: "")
        }
    }
}