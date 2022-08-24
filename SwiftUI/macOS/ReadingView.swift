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
    @State private var isSearchActive = false
    @StateObject private var searchViewModel = SearchViewModel()
    
    var body: some View {
        ReadingViewContent(url: $url, isSearchActive: $isSearchActive)
            .modifier(NavigationBarConfigurator())
            .modifier(SearchAdaptive(isSearchActive: $isSearchActive))
            .environmentObject(searchViewModel)
            .toolbar {
                #if os(macOS)
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
                #elseif os(iOS)
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if horizontalSizeClass == .regular {
                        NavigateBackButton()
                        NavigateForwardButton()
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if horizontalSizeClass == .compact, isSearchActive {
                        Button("Cancel") {
                            isSearchActive = false
                            searchViewModel.searchText = ""
                        }
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if horizontalSizeClass == .regular {
                        MainArticleMenu(url: $url)
                        RandomArticleMenu(url: $url)
                        BookmarkToggleButton(url: url)
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    if horizontalSizeClass == .compact, !isSearchActive {
                        Group {
                            NavigateBackButton()
                            Spacer()
                            NavigateForwardButton()
                        }
                        Spacer()
                        OutlineButton()
                        Spacer()
                        BookmarkMultiButton(url: url)
                        Spacer()
                        RandomArticleMenu(url: $url)
                        Spacer()
                        MoreActionMenu(url: $url)
                    }
                }
                #endif
            }
    }
}

@available(macOS 12.0, iOS 16.0, *)
private struct ReadingViewContent: View {
    @Binding var url: URL?
    @Binding var isSearchActive: Bool
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject private var searchViewModel: SearchViewModel
    
    var body: some View {
        Group {
            if url == nil {
                Welcome(url: $url)
            } else {
                WebView(url: $url).ignoresSafeArea(.container)
            }
        }
        .overlay {
            if isSearching || isSearchActive {
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
            isSearchActive = false
            dismissSearch()
        }
    }
}

@available(macOS 12.0, iOS 16.0, *)
private struct SearchAdaptive: ViewModifier {
    @Binding var isSearchActive: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var searchViewModel: SearchViewModel
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content.searchable(text: $searchViewModel.searchText)
        } else {
            #if os(macOS)
            content
            #elseif os(iOS)
            content.toolbar {
                ToolbarItem(placement: .principal) {
                    SearchBar(isSearchActive: $isSearchActive, searchText: $searchViewModel.searchText)
                }
            }
            #endif
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
            .toolbarBackground(.visible, for: .navigationBar, .bottomBar)
            .toolbarTitleMenu { OutlineMenuContent() }
        #endif
    }
}
