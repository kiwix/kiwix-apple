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

import SwiftUI

import Defaults

struct BrowserViewModelKey: FocusedValueKey {
    typealias Value = BrowserViewModel
}

struct IsBrowserURLSet: FocusedValueKey {
    typealias Value = Bool
}

struct CanGoBackKey: FocusedValueKey {
    typealias Value = Bool
}

struct CanGoForwardKey: FocusedValueKey {
    typealias Value = Bool
}

struct NavigationItemKey: FocusedValueKey {
    typealias Value = Binding<NavigationItem?>
}

extension FocusedValues {
    var isBrowserURLSet: IsBrowserURLSet.Value? {
        get { self[IsBrowserURLSet.self] }
        set { self[IsBrowserURLSet.self] = newValue }
    }

    var canGoBack: CanGoBackKey.Value? {
        get { self[CanGoBackKey.self] }
        set { self[CanGoBackKey.self] = newValue }
    }

    var canGoForward: CanGoForwardKey.Value? {
        get { self[CanGoForwardKey.self] }
        set { self[CanGoForwardKey.self] = newValue }
    }

    var navigationItem: NavigationItemKey.Value? {
        get { self[NavigationItemKey.self] }
        set { self[NavigationItemKey.self] = newValue }
    }
}

struct NavigationCommands: View {
    let goBack: () -> Void
    let goForward: () -> Void
    @FocusedValue(\.canGoBack) var canGoBack: Bool?
    @FocusedValue(\.canGoForward) var canGoForward: Bool?

    var body: some View {
        Button(LocalString.common_button_go_back) { goBack() }
            .keyboardShortcut("[")
            .disabled(canGoBack != true)
        Button(LocalString.common_button_go_forward) { goForward() }
            .keyboardShortcut("]")
            .disabled(canGoForward != true)
    }
}

struct PageZoomCommands: View {
    @Default(.webViewPageZoom) var webViewPageZoom
    @FocusedValue(\.isBrowserURLSet) var isBrowserURLSet: Bool?

    var body: some View {
        Button(LocalString.commands_button_actual_size) { webViewPageZoom = 1 }
            .keyboardShortcut("0")
            .disabled(webViewPageZoom == 1 || isBrowserURLSet != true)
        Button(LocalString.comments_button_zoom_in) { webViewPageZoom += 0.1 }
            .keyboardShortcut("+")
            .disabled(webViewPageZoom >= 2 || isBrowserURLSet != true)
        Button(LocalString.comments_button_zoom_out) { webViewPageZoom -= 0.1 }
            .keyboardShortcut("-")
            .disabled(webViewPageZoom <= 0.5 || isBrowserURLSet != true)
    }
}

#if os(macOS)
/// Only used on macOS
struct SidebarNavigationCommands: View {
    @FocusedBinding(\.navigationItem) var navigationItem: NavigationItem??

    var body: some View {
        buildButtons([.bookmarks], modifiers: [.command])
        if FeatureFlags.hasLibrary {
            Divider()
            buildButtons([.opened, .categories, .downloads, .new], modifiers: [.command, .control])
        }
    }

    private func buildButtons(_ navigationItems: [MenuItem], modifiers: EventModifiers = []) -> some View {
        ForEach(Array(navigationItems.enumerated()), id: \.element) { index, item in
            Button(item.name) {
                navigationItem = item.navigationItem
            }
            .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: modifiers)
            .disabled(navigationItem == nil)
        }
    }
}
#endif
