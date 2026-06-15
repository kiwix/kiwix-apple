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

import Defaults
import Foundation

enum ZIMsShowBy: Codable, Equatable, Defaults.Serializable {
    case all
    case onlyAvailable
    case onlyMissing
    
    func toggleNext() -> ZIMsShowBy {
        switch self {
        case .all: .onlyAvailable
        case .onlyAvailable: .onlyMissing
        case .onlyMissing: .all
        }
    }
    
    var title: String {
        switch self {
        case .all:
            LocalString.zim_file_opened_toolbar_filter_show_all
        case .onlyAvailable:
            LocalString.zim_file_opened_toolbar_filter_show_only_available
        case .onlyMissing:
            LocalString.zim_file_opened_toolbar_filter_show_only_missing
        }
    }
    
    var noResultsMessage: String {
        switch self {
        case .all:
            LocalString.zim_file_opened_overlay_no_zim_files_at_all_message
        case .onlyAvailable:
            LocalString.zim_file_opened_overlay_no_available_zim_files_message
        case .onlyMissing:
            LocalString.zim_file_opened_overlay_no_missing_zim_files_message
        }
    }
    
    var systemIcon: String {
        switch self {
        case .all:
            "square.grid.3x3.fill"
        case .onlyAvailable:
            "square.grid.3x3.topleft.filled"
        case .onlyMissing:
            "exclamationmark.triangle.fill"
        }
    }
    
    /// Highlights, if any content filtering is active (not showing all)
    var filterMenuSystemIcon: String {
        switch self {
        case .all:
            "line.3.horizontal.decrease.circle"
        case .onlyAvailable, .onlyMissing:
            "line.3.horizontal.decrease.circle.fill"
        }
    }
}
