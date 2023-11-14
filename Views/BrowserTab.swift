//
//  BrowserTab.swift
//  Kiwix
//
//  Created by Chris Li on 8/24/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

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
                        Label("Show Sidebar".localized, systemImage: "sidebar.left")
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
        .modifier(ExternalLinkHandler())
        .searchable(text: $search.searchText, placement: .toolbar)
        .modify { view in
            #if os(macOS)
            view.navigationTitle(browser.articleTitle.isEmpty ? "Kiwix" : browser.articleTitle)
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
                    } else if browser.url == nil {
                        Welcome()
                    } else {
                        WebView().ignoresSafeArea()
                    }
                }
            }
        }
    }
}
