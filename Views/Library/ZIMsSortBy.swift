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

enum ZIMsSortBy: Codable, Equatable, Defaults.Serializable {
    case name(SortOrder)
    case size(SortOrder)
    
    func toggleByName() -> ZIMsSortBy {
        switch self {
        case .name(.forward):
            .name(.reverse)
        case .name(.reverse), .size:
            .name(.forward)
        }
    }
    
    func toggleBySize() -> ZIMsSortBy {
        switch self {
        case .size(.forward):
            .size(.reverse)
        case .size(.reverse), .name:
            .size(.forward)
        }
    }
    
    func sortDescriptor() -> SortDescriptor<ZimFile> {
        switch self {
        case let .name(sortOrder):
            SortDescriptor(\ZimFile.name, order: sortOrder)
        case let .size(sortOrder):
            SortDescriptor(\ZimFile.size, order: sortOrder)
        }
    }
    
    static let byNameTitle = LocalString.zim_file_opened_toolbar_sort_by_name
    static let bySizeTitle = LocalString.zim_file_opened_toolbar_sort_by_size
    
    var systemIcon: String {
        switch self {
        case .name(.forward), .size(.forward): "arrow.down"
        default: "arrow.up"
        }
    }
    
    var isByName: Bool {
        switch self {
        case .name: return true
        case .size: return false
        }
    }
    
    var isBySize: Bool {
        switch self {
        case .name: return false
        case .size: return true
        }
    }
}
