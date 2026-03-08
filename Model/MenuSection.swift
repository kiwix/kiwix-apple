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

#if os(iOS)

import Foundation

// iPad only
enum MenuSection: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case tabs
    case primary
    case library
    case settings
    case donation
    
    static var allMenuSections: [MenuSection] {
        switch (FeatureFlags.hasLibrary, Brand.hideDonation) {
        case (true, true):
            allCases.filter { ![.donation].contains($0) }
        case (false, true):
            allCases.filter { ![.donation, .library].contains($0) }
        case (true, false):
            allCases
        case (false, false):
            allCases.filter { ![.library].contains($0) }
        }
    }
    
    var header: String? {
        switch self {
        case .library: return LocalString.common_tab_menu_library
        default: return nil
        }
    }
    
    static var staticDictionary: [MenuSection: [MenuItem]] {
        var dict: [MenuSection: [MenuItem]] = [:]
        for section in allMenuSections {
            dict[section] = itemsFor(section)
        }
        return dict
    }
    
    static func itemsFor(_ section: MenuSection) -> [MenuItem] {
        switch section {
        case .primary: return [.bookmarks]
        case .library: return [.opened, .categories, .downloads, .new, .hotspot]
        case .settings:
            if !FeatureFlags.hasLibrary {
                return [.hotspot, .settings(scrollToHotspot: false)]
            } else {
                return [.settings(scrollToHotspot: false)]
            }
            // initially empty, we load them async
        case .tabs: return []
        case .donation: return []
        }
    }
}

#endif
