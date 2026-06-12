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

#if os(macOS)
import AppKit
import Foundation

struct WindowState: Codable, Hashable {
    let frame: CGRect
    let identifier: String
    let keyWindowId: String?
    let menuItemId: String
    let otherTabIds: [String]
    let selectedTabId: String?
    
    var isLastTab: Bool {
        tabIndex == otherTabIds.count - 1
    }
    
    /// This helps to toggle between prefered new tab vs new window
    /// when restoring the session
    var openInNewTab: Bool {
        if let tabIndex {
            tabIndex > 0
        } else {
            false
        }
    }
    
    var tabIndex: Int? {
        otherTabIds.firstIndex(of: identifier)
    }
    
    @MainActor
    init?(window: NSWindow, menuItemId menuId: String) {
        menuItemId = menuId
        identifier = window.accessibilityIdentifier()
        selectedTabId = window.tabGroup?.selectedWindow?.accessibilityIdentifier()
        otherTabIds = window.tabGroup?.windows.map { $0.accessibilityIdentifier() } ?? []
        frame = window.frame
        keyWindowId = NSApplication.shared.keyWindow?.accessibilityIdentifier()
    }
}

extension Array where Element == WindowState {
    func groupByTabs() -> [[String]: [WindowState]] {
        Dictionary(grouping: self) { windowState in
            windowState.otherTabIds
        }
    }
}

#endif
