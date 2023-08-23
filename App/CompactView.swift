//
//  CompactView.swift
//  Kiwix
//
//  Created by Chris Li on 8/16/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

#if os(iOS)
@available(iOS 16.0, *)
struct CompactView: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    
    var body: some View {
        if case let .tab(tabID) = navigation.currentItem {
            Content().id(tabID).environmentObject(WebViewCache.shared.getViewModel(tabID: tabID))
        }
    }
}

@available(iOS 16.0, *)
private struct Content: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @EnvironmentObject private var search: SearchViewModel
    
    var body: some View {
        Group {
            if search.isSearching {
                SearchResults()
            } else if browser.url == nil {
                Welcome()
            } else {
                WebView().ignoresSafeArea()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if search.isSearching {
                    Button("Cancel") {
                        search.isSearching = false
                    }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if !search.isSearching {
                    NavigationButtons()
                    Spacer()
                    OutlineButton()
                    Spacer()
                    BookmarkButton()
                    Spacer()
                    RandomArticleButton()
                    Spacer()
                    TabsManagerButton()
                }
            }
        }
        .focusedSceneValue(\.browserViewModel, browser)
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
    }
}
#endif
