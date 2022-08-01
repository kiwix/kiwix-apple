//
//  ReadingView.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ReadingView: View {
    @Binding var url: URL?
    @Environment(\.isSearching) private var isSearching
    @State private var articleTitle = ""
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var navigationAction: ReadingViewNavigationAction?
    
    var body: some View {
        WebView(
            articleTitle: $articleTitle,
            canGoBack: $canGoBack,
            canGoForward: $canGoForward,
            navigationAction: $navigationAction,
            url: $url
        )
        .ignoresSafeArea(edges: .all)
        .overlay(alignment: .top) {
            if isSearching {
                List {
                    Text("result 1")
                    Text("result 2")
                    Text("result 3")
                }
            } else if url == nil {
                Welcome(url: $url)
            }
        }
        .navigationTitle(articleTitle)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                ControlGroup {
                    Button {
                        navigationAction = .goBack
                    } label: { Image(systemName: "chevron.backward") }.disabled(!canGoBack)
                    Button {
                        navigationAction = .goForward
                    } label: { Image(systemName: "chevron.forward") }.disabled(!canGoForward)
                }
            }
        }
    }
}

enum ReadingViewNavigationAction {
    case goBack, goForward
}
