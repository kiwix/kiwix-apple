//
//  BrowserTab.swift
//  Kiwix
//
//  Created by Chris Li on 7/1/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

@available(iOS 16.0, *)
struct BrowserTabRegular: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @StateObject private var browser = BrowserViewModel()
    @StateObject private var search = SearchViewModel()
    
    let tabID: NSManagedObjectID
    
    var body: some View {
        Content(tabID: tabID).toolbar {
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
        .environmentObject(browser)
        .environmentObject(search)
        .searchable(text: $search.searchText, placement: .toolbar)
        .onAppear {
            navigation.updateTab(tabID: tabID, lastOpened: Date())
            browser.configure(tabID: tabID, webView: navigation.getWebView(tabID: tabID))
        }
        .modify { view in
            #if os(macOS)
            if browserViewModel.articleTitle.isEmpty {
                view.navigationTitle("Kiwix")
            } else {
                view.navigationTitle(browserViewModel.articleTitle).navigationSubtitle(browserViewModel.zimFileName)
            }
            #elseif os(iOS)
            view.navigationBarTitleDisplayMode(.inline)
                .navigationTitle(browser.articleTitle)
                .toolbarRole(.browser)
                .toolbarBackground(.visible, for: .navigationBar)
            #endif
        }
    }
    
    struct Content: View {
        @Environment(\.isSearching) private var isSearching
        @EnvironmentObject private var browser: BrowserViewModel
        @EnvironmentObject private var navigation: NavigationViewModel
        
        let tabID: NSManagedObjectID
        
        var body: some View {
            Group {
                if browser.url == nil {
                    List { Text("Welcome") }
                } else {
                    WebView(view: navigation.getWebView(tabID: tabID)).ignoresSafeArea()
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

@available(iOS 16.0, *)
struct BrowserTabCompact: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @StateObject private var browser = BrowserViewModel()
    
    let tabID: NSManagedObjectID
    
    var body: some View {
        Group {
            if browser.url == nil {
                List { Text("Welcome") }
            } else {
                WebView(view: navigation.getWebView(tabID: tabID)).ignoresSafeArea()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
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
        .environmentObject(browser)
        .onAppear {
            navigation.updateTab(tabID: tabID, lastOpened: Date())
            browser.configure(tabID: tabID, webView: navigation.getWebView(tabID: tabID))
        }
    }
}
