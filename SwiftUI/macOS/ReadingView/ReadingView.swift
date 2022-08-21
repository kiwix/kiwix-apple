//
//  ReadingView.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

@available(macOS 12.0, iOS 16.0, *)
struct ReadingView: View {
    @Binding var url: URL?
    @StateObject private var searchViewModel = SearchViewModel()
    
    var body: some View {
        ReadingViewContent(url: $url, searchText: $searchViewModel.searchText)
            .environmentObject(searchViewModel)
            .searchable(text: $searchViewModel.searchText)
            .modifier(NavigationBarConfigurator())
            .toolbar {
                #if os(macOS)
                ToolbarItemGroup(placement: .navigation) {
                    ControlGroup {
                        NavigateBackButton()
                        NavigateForwardButton()
                    }
                }
                #elseif os(iOS)
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    NavigateBackButton()
                    NavigateForwardButton()
                }
                #endif
                ToolbarItemGroup {
                    OutlineMenu()
                    BookmarkToggleButton(url: url)
                    #if os(macOS)
                    RandomArticleButton(url: $url)
                    MainArticleButton(url: $url)
                    #elseif os(iOS)
                    RandomArticleMenu(url: $url)
                    MainArticleMenu(url: $url)
                    #endif
                }
            }
    }
}

@available(macOS 12.0, iOS 16.0, *)
private struct ReadingViewContent: View {
    @Binding var url: URL?
    @Binding var searchText: String
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.isSearching) private var isSearching
    
    var body: some View {
        Group {
            if url == nil {
                Welcome(url: $url)
            } else {
                WebView(url: $url).ignoresSafeArea(edges: .all)
            }
        }
        .onTapGesture {
            searchText = ""
            dismissSearch()
        }
        .overlay {
            if isSearching {
                SearchView(url: $url, searchText: $searchText)
            }
        }
        .onChange(of: url) { _ in
            searchText = ""
            dismissSearch()
        }
    }
}

@available(macOS 12.0, iOS 16.0, *)
private struct NavigationBarConfigurator: ViewModifier {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .navigationTitle(viewModel.articleTitle)
            .navigationSubtitle(viewModel.zimFileName)
        #elseif os(iOS)
        content
            .navigationTitle(viewModel.articleTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.browser)
            .toolbarBackground(.visible, for: .navigationBar)
        #endif
    }
}
