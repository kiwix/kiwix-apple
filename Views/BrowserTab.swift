/*
 * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

import SwiftUI

struct BrowserTab: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @StateObject private var search = SearchViewModel()

    var body: some View {
        Content().toolbar {
            #if os(macOS)
            ToolbarItemGroup(placement: .navigation) { NavigationButtons() }
            #elseif os(iOS)
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if #unavailable(iOS 16) {
                    Button {
                        NotificationCenter.toggleSidebar()
                    } label: {
                        Label("browser_tab.toolbar.show_sidebar.label".localized, systemImage: "sidebar.left")
                    }
                }
                NavigationButtons()
            }
            #endif
            ToolbarItemGroup(placement: .primaryAction) {
                OutlineButton()
                BookmarkButton()
                ArticleShortcutButtons(displayMode: .mainAndRandomArticle)
            }
        }
        .environmentObject(search)
        .focusedSceneValue(\.browserViewModel, browser)
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
        .modifier(ExternalLinkHandler(externalURL: $browser.externalURL))
        .searchable(text: $search.searchText, placement: .toolbar, prompt: "common.search".localized)
        .modify { view in
            #if os(macOS)
            view.navigationTitle(browser.articleTitle.isEmpty ? Brand.appName : browser.articleTitle)
                .navigationSubtitle(browser.zimFileName)
            #elseif os(iOS)
            view
            #endif
        }
        .onAppear {
            browser.updateLastOpened()
        }
        .onDisappear {
            browser.persistState()
        }
    }
    
    struct Content: View {
        @Environment(\.isSearching) private var isSearching
        @EnvironmentObject private var browser: BrowserViewModel

        var body: some View {
            GeometryReader { proxy in
                Group {
                    if isSearching {
                        SearchResults()
                            #if os(macOS)
                            .environment(\.horizontalSizeClass, proxy.size.width > 650 ? .regular : .compact)
                            #elseif os(iOS)
                            .environment(\.horizontalSizeClass, proxy.size.width > 750 ? .regular : .compact)
                            #endif
                    } else if browser.url == nil && FeatureFlags.hasLibrary {
                        Welcome()
                    } else {
                        WebView().ignoresSafeArea()
                    }
                }
            }
        }
    }
}
