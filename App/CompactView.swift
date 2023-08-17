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
    @EnvironmentObject private var search: SearchViewModel
    @StateObject private var browser = BrowserViewModel()
    
    var body: some View {
        Group {
            if search.isSearching {
                SearchResults()
            } else if case let .tab(tabID) = navigation.currentItem, browser.url != nil {
                WebView(tabID: tabID).ignoresSafeArea().id(tabID)
            } else {
                Welcome()
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
        .environmentObject(browser)
        .focusedSceneValue(\.browserViewModel, browser)
        .onAppear {
            guard case let .tab(tabID) = navigation.currentItem else { return }
            browser.configure(tabID: tabID)
        }
        .onChange(of: navigation.currentItem) { navigationItem in
            guard case let .tab(tabID) = navigation.currentItem else { return }
            browser.configure(tabID: tabID)
        }
    }
}
#endif
