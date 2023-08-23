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
            ToolbarItemGroup(placement: .navigationBarLeading) { NavigationButtons() }
            #endif
        }
        .environmentObject(search)
        .focusedSceneValue(\.browserViewModel, browser)
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
        .modifier(ExternalLinkHandler())
        .searchable(text: $search.searchText, placement: .toolbar)
        .modify { view in
            #if os(macOS)
            view
            #elseif os(iOS)
            if #available(iOS 16.0, *) {
                view.toolbarBackground(.visible, for: .navigationBar)
            } else {
                view
            }
            #endif
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
                            .environment(\.horizontalSizeClass, proxy.size.width > 750 ? .regular : .compact)
                    } else if browser.url == nil {
                        Welcome()
                    } else {
                        WebView().ignoresSafeArea()
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        if proxy.size.width > 750 || !isSearching {
                            OutlineButton()
                            BookmarkButton()
                            RandomArticleButton()
                            MainArticleButton()
                        }
                    }
                }
                .modify { view in
                    #if os(macOS)
                    view.navigationTitle(browser.articleTitle.isEmpty ? "Kiwix" : browser.articleTitle)
                        .navigationSubtitle(browser.zimFileName)
                    #elseif os(iOS)
                    if #available(iOS 16.0, *), proxy.size.width > 750 || !isSearching {
                        view.navigationTitle(browser.articleTitle).navigationBarTitleDisplayMode(.inline)
                    } else {
                        view
                    }
                    #endif
                }
            }
        }
    }
}
