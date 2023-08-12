//
//  ReadingView.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

#if os(macOS)
struct ReadingView: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @StateObject private var browser = BrowserViewModel()
    @StateObject private var search = SearchViewModel()
    
    var body: some View {
        Content().toolbar {
            ToolbarItemGroup(placement: .navigation) { NavigationButtons() }
            ToolbarItemGroup(placement: .primaryAction) {
                OutlineButton()
                BookmarkButton()
                RandomArticleButton()
                MainArticleButton()
            }
        }
        .environmentObject(browser)
        .environmentObject(search)
        .searchable(text: $search.searchText, placement: .toolbar)
        .navigationTitle(browser.articleTitle.isEmpty ? "Kiwix" : browser.articleTitle)
        .navigationSubtitle(browser.zimFileName)
        .onAppear {
            browser.configure(tabID: nil, webView: navigation.webView)
        }
    }
    
    struct Content: View {
        @Environment(\.isSearching) private var isSearching
        @EnvironmentObject private var browser: BrowserViewModel
        
        var body: some View {
            Group {
                if browser.url == nil {
                    List { Text("Welcome") }
                } else {
                    WebView().ignoresSafeArea()
                }
            }.overlay {
                if isSearching {
                    GeometryReader { proxy in
                        SearchResults().environment(\.horizontalSizeClass, proxy.size.width > 700 ? .regular : .compact)
                    }
                }
            }
        }
    }
}
#endif
