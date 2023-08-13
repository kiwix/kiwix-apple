//
//  BrowserTab.swift
//  Kiwix
//
//  Created by Chris Li on 7/1/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

#if os(iOS)
@available(iOS 16.0, *)
struct BrowserTab: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @StateObject private var browser = BrowserViewModel()
    @StateObject private var search = SearchViewModel()
    
    let tabID: NSManagedObjectID
    
    var body: some View {
        Content(tabID: tabID).toolbar {
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
        .searchable(text: $search.searchText, placement: .toolbar)
        .navigationBarTitle(browser.articleTitle)  // avoid _UIModernBarButton related constraint error
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.browser)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            navigation.updateTab(tabID: tabID, lastOpened: Date())
            browser.configure(tabID: tabID, webView: navigation.getWebView(tabID: tabID))
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
                    Welcome()
                } else {
                    WebView(tabID: tabID).ignoresSafeArea()
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
