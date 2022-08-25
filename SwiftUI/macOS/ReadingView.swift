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
/// A view that show article content, along with welcome view, search view, and various controls like
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
            if url == nil {
                Welcome(url: $url)
            } else {
                WebView(url: $url).ignoresSafeArea(.container)
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
        .onChange(of: url) { _ in
            searchViewModel.searchText = ""
            dismissSearch()
        }
        #if os(macOS)
        .navigationTitle(readingViewModel.articleTitle)
        .navigationSubtitle(readingViewModel.zimFileName)
        .onTapGesture {
            searchViewModel.searchText = ""
            dismissSearch()
        }
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
        .modifier(NavigationTitleConfigurator())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $readingViewModel.activeSheet) { activeSheet in
            switch activeSheet {
            case .outline:
                SheetView { OutlineTree().listStyle(.plain).navigationBarTitleDisplayMode(.inline) }
            case .bookmarks:
                SheetView { BookmarksView(url: $url) }
            case .library:
                Library()
            case .settings:
                SheetView { SettingsView() }
            }
        }
        .toolbarRole(.browser)
        .toolbarBackground(.visible, for: .navigationBar, .bottomBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if horizontalSizeClass == .regular {
                    NavigateBackButton()
                    NavigateForwardButton()
                }
            }
            ToolbarItemGroup(placement: .secondaryAction) {
                if horizontalSizeClass == .regular {
                    OutlineMenu()
                    BookmarkToggleButton(url: url)
                    RandomArticleMenu(url: $url)
                    MainArticleMenu(url: $url)
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if horizontalSizeClass == .compact {
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
        }
        #endif
    }
}

@available(macOS 12.0, iOS 15.0, *)
private struct NavigationTitleConfigurator: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject private var readingViewModel: ReadingViewModel
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content.navigationTitle(readingViewModel.articleTitle)
        } else {
            content.toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if !isSearching {
                        Text(compactTitle).fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    private var compactTitle: String {
        readingViewModel.articleTitle.isEmpty ? "Kiwix" : readingViewModel.articleTitle
    }
}
