//
//  RegularView.swift
//  Kiwix
//
//  Created by Chris Li on 7/1/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

#if os(iOS)
@available(iOS 16.0, *)
struct RegularView: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    
    private let primaryItems: [NavigationItem] = [.bookmarks, .settings]
    private let libraryItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
        NavigationSplitView {
            List(selection: $navigation.currentItem) {
                ForEach(primaryItems, id: \.self) { navigationItem in
                    Label(navigationItem.name, systemImage: navigationItem.icon)
                }
                Section("Tabs") {
                    TabsSectionContent()
                }
                Section("Library") {
                    ForEach(libraryItems, id: \.self) { navigationItem in
                        Label(navigationItem.name, systemImage: navigationItem.icon)
                    }
                }
            }
            .navigationTitle("Kiwix")
            .toolbar { NewTabButton() }
        } detail: {
            NavigationStack { content.navigationBarTitleDisplayMode(.inline).toolbarRole(.browser) }
        }
    }
    
    @ViewBuilder
    @available(iOS 16.0, *)
    private var content: some View {
        switch navigation.currentItem {
        case .bookmarks:
            Bookmarks()
        case .settings:
            Settings()
        case .tab:
            RegularTab()
        case .opened:
            ZimFilesOpened()
        case .categories:
            ZimFilesCategories()
        case .downloads:
            ZimFilesDownloads()
        case .new:
            ZimFilesNew()
        default:
            EmptyView()
        }
    }
}

@available(iOS 16.0, *)
private struct RegularTab: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @StateObject private var browser = BrowserViewModel()
    @StateObject private var search = SearchViewModel()
    
    var body: some View {
        Content().toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) { NavigationButtons() }
            ToolbarItemGroup(placement: .primaryAction) {
                OutlineButton()
                BookmarkButton()
                RandomArticleButton()
                MainArticleButton()
            }
        }
        .environmentObject(browser)
        .environmentObject(search)
        .focusedSceneValue(\.browserViewModel, browser)
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
        .searchable(text: $search.searchText, placement: .toolbar)
        .navigationBarTitle(browser.articleTitle)  // avoid _UIModernBarButton related constraint error
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.browser)
        .toolbarBackground(.visible, for: .navigationBar)
        .modifier(ExternalLinkHandler())
        .onAppear {
            guard case let .tab(tabID) = navigation.currentItem else { return }
            browser.configure(tabID: tabID)
        }
        .onChange(of: navigation.currentItem) { navigationItem in
            guard case let .tab(tabID) = navigation.currentItem else { return }
            browser.configure(tabID: tabID)
        }
    }
    
    struct Content: View {
        @Environment(\.isSearching) private var isSearching
        @EnvironmentObject private var browser: BrowserViewModel
        @EnvironmentObject private var navigation: NavigationViewModel
        
        var body: some View {
            Group {
                if case let .tab(tabID) = navigation.currentItem, browser.url != nil {
                    WebView(tabID: tabID).ignoresSafeArea().id(tabID)
                } else {
                    Welcome()
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
