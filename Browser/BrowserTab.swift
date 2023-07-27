//
//  BrowserTab.swift
//  Kiwix
//
//  Created by Chris Li on 7/1/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

struct BrowserTab: View {
    @EnvironmentObject private var browserViewModel: BrowserViewModel
    @StateObject private var searchViewModel = SearchViewModel()
    
    var body: some View {
        Content()
            .environmentObject(searchViewModel)
            .searchable(text: $searchViewModel.searchText, placement: .toolbar)
            .toolbar {
                #if os(macOS)
                ToolbarItemGroup(placement: .navigation) { NavigationButtons() }
                #elseif os(iOS)
                ToolbarItemGroup(placement: .navigationBarLeading) { NavigationButtons() }
                #endif
                ToolbarItemGroup(placement: .primaryAction) {
                    OutlineButton()
                    BookmarkButton()
                    RandomArticleButton()
                    MainArticleButton()
                }
            }
            .modifier(ToolbarRoleBrowser())
            .modify { view in
                #if os(macOS)
                if browserViewModel.articleTitle.isEmpty {
                    view.navigationTitle("Kiwix")
                } else {
                    view.navigationTitle(browserViewModel.articleTitle).navigationSubtitle(browserViewModel.zimFileName)
                }
                #elseif os(iOS)
                view
                #endif
            }
    }
}

private struct Content: View {
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject private var viewModel: BrowserViewModel
    
    var body: some View {
        Group {
            if viewModel.url == nil {
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
