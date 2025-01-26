// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Foundation

public enum LibraryRefreshError: LocalizedError {
    case retrieve(description: String?)
    case parse
    case process

    public var errorDescription: String? {
        switch self {
        case .retrieve(let description):
            let prefix = LocalString.library_refresh_error_retrieve_description
            return [prefix, description].compactMap({ $0 }).joined(separator: " ")
        case .parse:
            return LocalString.library_refresh_error_parse_description
        case .process:
            return LocalString.library_refresh_error_process_description
        }
    }
}
