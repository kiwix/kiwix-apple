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
    var browserViewModel: BrowserViewModelKey.Value? {
        get { self[BrowserViewModelKey.self] }
        set { self[BrowserViewModelKey.self] = newValue }
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
    @FocusedValue(\.canGoBack) var canGoBack: Bool?
    @FocusedValue(\.canGoForward) var canGoForward: Bool?
    @FocusedValue(\.browserViewModel) var browser: BrowserViewModel?

    var body: some View {
        Button("common.button.go_back".localized) { browser?.webView.goBack() }
            .keyboardShortcut("[")
            .disabled(canGoBack != true)
        Button("common.button.go_forward".localized) { browser?.webView.goForward() }
            .keyboardShortcut("]")
            .disabled(canGoForward != true)
    }
}

struct PageZoomCommands: View {
    @Default(.webViewPageZoom) var webViewPageZoom
    @FocusedValue(\.browserViewModel) var browser: BrowserViewModel?

    var body: some View {
        Button("commands.button.actual_size".localized) { webViewPageZoom = 1 }
            .keyboardShortcut("0")
            .disabled(webViewPageZoom == 1 || browser?.url == nil)
        Button("comments.button.zoom_in".localized) { webViewPageZoom += 0.1 }
            .keyboardShortcut("+")
            .disabled(webViewPageZoom >= 2 || browser?.url == nil)
        Button("comments.button.zoom_out".localized) { webViewPageZoom -= 0.1 }
            .keyboardShortcut("-")
            .disabled(webViewPageZoom <= 0.5 || browser?.url == nil)
    }
}

/// Only used on macOS
struct SidebarNavigationCommands: View {
    @FocusedBinding(\.navigationItem) var navigationItem: NavigationItem??
    @EnvironmentObject var navigation: NavigationViewModel

    var body: some View {
        buildButtons([.tab(objectID: navigation.currentTabId), .bookmarks], modifiers: [.command])
        if FeatureFlags.hasLibrary {
            Divider()
            buildButtons([.opened, .categories, .downloads, .new], modifiers: [.command, .control])
        }
    }

    private func buildButtons(_ navigationItems: [NavigationItem], modifiers: EventModifiers = []) -> some View {
        ForEach(Array(navigationItems.enumerated()), id: \.element) { index, item in
            Button(item.name) {
                navigationItem = item
            }
            .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: modifiers)
            .disabled(navigationItem == nil)
        }
    }
}
