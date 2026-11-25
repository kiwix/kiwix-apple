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

import CoreData
import Defaults
import Foundation
import SwiftUI

enum IconSource {
    case system(String)
    case image(String)
}

enum MenuItem: Hashable, Identifiable, RawRepresentable, Defaults.Serializable {
    typealias RawValue = String

    init?(rawValue: String) {
        guard let url = URL(string: rawValue) else {
            return nil
        }
        if url.scheme == "menu" {
            let identifier = url.absoluteString.trimmingPrefix("menu://")
            if let item = [
                MenuItem.bookmarks,
                .explore,
                .donation,
                .downloads,
                .hotspot,
                .library,
                .settings(scrollToHotspot: false)
            ].first(where: { $0.id == identifier }) {
                self = item
            } else {
                return nil
            }
        } else {
            let viewContext = Database.shared.viewContext
            guard let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(
                forURIRepresentation: url
            ) else {
                return nil
            }
            self = .tab(objectID: objectID)
        }
    }

    var rawValue: String {
        switch self {
        case let .tab(objectID):
            return objectID.uriRepresentation().absoluteString
        default:
            return urlFor(id).absoluteString
        }
    }
    
    private func urlFor(_ value: String) -> URL {
        URL(string: "menu://\(value)")!
    }
    
    case tab(objectID: NSManagedObjectID)
    case bookmarks
    case library
    case explore
    case downloads
    case settings(scrollToHotspot: Bool)
    case donation
    case hotspot
    
    init?(from navigationItem: NavigationItem) {
        switch navigationItem {
        case .loading, .map: return nil
        case .bookmarks: self = .bookmarks
        case .tab(let objectID): self = .tab(objectID: objectID)
        case .opened: self = .library
        case .explore: self = .explore
        case .downloads: self = .downloads
        case let .settings(scrollToHotspot): self = .settings(scrollToHotspot: scrollToHotspot)
        case .hotspot: self = .hotspot
        }
    }
    
    var navigationItem: NavigationItem? {
        switch self {
        case .tab(objectID: let objectID): .tab(objectID: objectID)
        case .bookmarks: .bookmarks
        case .library: .opened
        case .explore: .explore
        case .downloads: .downloads
        // by selecting the side menu settings, we don't want to scroll
        case .settings: .settings(scrollToHotspot: false)
        case .donation: nil
        case .hotspot: .hotspot
        }
    }
    
    var name: String {
        switch self {
        case .bookmarks:
            return LocalString.enum_navigation_item_bookmarks
        case .tab:
#if os(macOS)
            return LocalString.enum_navigation_item_reading
#else
            return LocalString.enum_navigation_item_new_tab
#endif
        case .library:
            return LocalString.enum_navigation_item_library
        case .explore:
            return LocalString.enum_navigation_item_explore
        case .downloads:
            return LocalString.enum_navigation_item_downloads
        case .settings:
            return LocalString.enum_navigation_item_settings
        case .donation:
            return LocalString.payment_support_button_label
        case .hotspot:
            return LocalString.enum_navigation_item_hotspot
        }
    }
    
    var accessibilityIdentifier: String {
        id
    }

    var id: String {
        switch self {
        case .tab:
            "tab"
        case .bookmarks:
            "bookmarks"
        case .library:
            "opened" // backward compatibility
        case .explore:
            "categories" // backward compatibility
        case .downloads:
            "downloads"
        case .settings:
            "settings"
        case .donation:
            "donation"
        case .hotspot:
            "hotspot"
        }
    }
    
    var icon: IconSource {
        switch self {
        case .bookmarks:
            return IconSource.system("star")
        case .tab:
            #if os(macOS)
            return IconSource.system("book")
            #else
            return IconSource.system("square")
            #endif
        case .library:
            return IconSource.system("books.vertical")
        case .explore:
            return IconSource.image("telescope")
        case .downloads:
            return IconSource.system("tray.and.arrow.down")
        case .settings:
            return IconSource.system("gear")
        case .donation:
            return IconSource.system("heart.fill")
        case .hotspot:
            return IconSource.system("wifi")
        }
    }
    #if os(iOS)
    var iconForegroundColor: UIColor? {
        switch self {
        case .donation:
            return UIColor.red
        case .tab, .bookmarks, .library, .explore, .downloads, .hotspot, .settings:
            return nil
        }
    }
    #endif
}
