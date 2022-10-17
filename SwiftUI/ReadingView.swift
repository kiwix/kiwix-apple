//
//  ReadingView.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

import Introspect

/// A view that show article content, along with welcome view, search view, and various article controls
@available(macOS 12.0, iOS 16.0, *)
struct ReadingView: View {
    @Binding var url: URL?
    @StateObject private var searchViewModel = SearchViewModel()
    
    var body: some View {
        ReadingViewContent(url: $url)
            .searchable(text: $searchViewModel.searchText, placement: .toolbar)
            .environmentObject(searchViewModel)
    }
}

@available(macOS 12.0, iOS 16.0, *)
private struct ReadingViewContent: View {
    @Binding var url: URL?
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject private var readingViewModel: ReadingViewModel
    @EnvironmentObject private var searchViewModel: SearchViewModel
    
    var body: some View {
        Group {
            if isSearching {
                GeometryReader { proxy in
                    Search() { result in
                        url = result.url
                        dismissSearch()
                    }
                    .safeAreaInset(edge: .top) { Divider() }
                    .environment(\.horizontalSizeClass, proxy.size.width > 700 ? .regular : .compact)
                }
            } else if url == nil {
                Welcome(url: $url)
            } else {
                WebView(url: $url).ignoresSafeArea(.container)
            }
        }
        .onChange(of: url) { _ in dismissSearch() }
        .focusedSceneValue(\.canGoBack, readingViewModel.canGoBack)
        .focusedSceneValue(\.canGoForward, readingViewModel.canGoForward)
        .focusedSceneValue(\.readingViewModel, readingViewModel)
        #if os(macOS)
        .navigationTitle(url == nil ? "Kiwix" : readingViewModel.articleTitle)
        .navigationSubtitle(readingViewModel.zimFileName)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                ControlGroup {
                    NavigateBackButton()
                    NavigateForwardButton()
                }
            }
            ToolbarItemGroup {
                OutlineMenu()
                BookmarkToggleButton(url: url)
                RandomArticleButton(url: $url)
                MainArticleButton(url: $url)
            }
        }
        #elseif os(iOS)
        .navigationTitle(readingViewModel.articleTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.browser)
        .toolbarBackground(.visible, for: .navigationBar, .bottomBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                NavigateBackButton()
                NavigateForwardButton()
            }
            ToolbarItemGroup(placement: .primaryAction) {
                OutlineMenu()
                BookmarkToggleButton(url: url)
                RandomArticleMenu(url: $url)
                MainArticleMenu(url: $url)
            }
        }
        #endif
    }
}
