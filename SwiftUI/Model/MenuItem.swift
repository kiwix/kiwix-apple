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
import Foundation
import SwiftUI

enum MenuItem: Hashable, Identifiable, RawRepresentable {
    typealias RawValue = String

    init?(rawValue: String) {
        guard let url = URL(string: rawValue) else {
            return nil
        }
        if url.scheme == "menu" {
            let identifier = url.absoluteString.trimmingPrefix("menu://")
            if let item = [
                MenuItem.bookmarks,
                .categories,
                .donation,
                .downloads,
                .hotspot,
                .new,
                .opened,
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
    case opened
    case categories
    case new
    case downloads
    case settings(scrollToHotspot: Bool)
    case donation
    case hotspot
    
    init?(from navigationItem: NavigationItem) {
        switch navigationItem {
        case .loading, .map: return nil
        case .bookmarks: self = .bookmarks
        case .tab(let objectID): self = .tab(objectID: objectID)
        case .opened: self = .opened
        case .categories: self = .categories
        case .new: self = .new
        case .downloads: self = .downloads
        case let .settings(scrollToHotspot): self = .settings(scrollToHotspot: scrollToHotspot)
        case .hotspot: self = .hotspot
        }
    }
    
    var navigationItem: NavigationItem? {
        switch self {
        case .tab(objectID: let objectID): .tab(objectID: objectID)
        case .bookmarks: .bookmarks
        case .opened: .opened
        case .categories: .categories
        case .new: .new
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
        case .opened:
            return LocalString.enum_navigation_item_opened
        case .categories:
            return LocalString.enum_navigation_item_categories
        case .new:
            return LocalString.enum_navigation_item_new
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
        case .opened:
            "opened"
        case .categories:
            "categories"
        case .new:
            "new"
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
    
    var icon: String {
        switch self {
        case .bookmarks:
            return "star"
        case .tab:
            #if os(macOS)
            return "book"
            #else
            return "square"
            #endif
        case .opened:
            return "folder"
        case .categories:
            return "books.vertical"
        case .new:
            return "newspaper"
        case .downloads:
            return "tray.and.arrow.down"
        case .settings:
            return "gear"
        case .donation:
            return "heart.fill"
        case .hotspot:
            return "wifi"
        }
    }
    #if os(iOS)
    var iconForegroundColor: UIColor? {
        switch self {
        case .donation:
            return UIColor.red
        case .tab, .bookmarks, .opened, .categories, .new, .downloads, .hotspot, .settings:
            return nil
        }
    }
    #endif
}
