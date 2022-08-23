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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var searchViewModel = SearchViewModel()
    
    var body: some View {
        ReadingViewContent(url: $url)
            .modifier(NavigationBarConfigurator())
            .modifier(SearchAdaptive())
            .environmentObject(searchViewModel)
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
                    if horizontalSizeClass == .regular {
                        NavigateBackButton()
                        NavigateForwardButton()
                    }
                }
                #endif
                ToolbarItemGroup {
                    if horizontalSizeClass == .regular {
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
}

@available(macOS 12.0, iOS 16.0, *)
private struct ReadingViewContent: View {
    @Binding var url: URL?
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject private var searchViewModel: SearchViewModel
    
    var body: some View {
        Group {
            if url == nil {
                Welcome(url: $url)
            } else {
                WebView(url: $url).ignoresSafeArea(edges: .all)
            }
        }
        .overlay {
            if isSearching {
                SearchView(url: $url)
                #if os(macOS)
                    .environment(\.horizontalSizeClass, .compact)
                #endif
            }
        }
        .onTapGesture {
            searchViewModel.searchText = ""
            dismissSearch()
        }
        .onChange(of: url) { _ in
            searchViewModel.searchText = ""
            dismissSearch()
        }
    }
}

@available(macOS 12.0, iOS 16.0, *)
private struct SearchBar: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        return searchBar
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

@available(macOS 12.0, iOS 16.0, *)
private struct SearchAdaptive: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var searchViewModel: SearchViewModel
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content.searchable(text: $searchViewModel.searchText)
        } else {
            content.toolbar {
                ToolbarItem(placement: .principal) {
                    SearchBar()
                }
            }
        }
    }
}

@available(macOS 12.0, iOS 16.0, *)
private struct NavigationBarConfigurator: ViewModifier {
    @EnvironmentObject private var readingViewModel: ReadingViewModel
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .navigationTitle(readingViewModel.articleTitle)
            .navigationSubtitle(readingViewModel.zimFileName)
        #elseif os(iOS)
        content
            .navigationTitle(readingViewModel.articleTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.browser)
            .toolbarBackground(.visible, for: .navigationBar)
        #endif
    }
}
