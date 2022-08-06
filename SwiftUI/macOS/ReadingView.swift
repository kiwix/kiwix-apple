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
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Group {
            if isSearching {
                List {
                    Text("result 1")
                    Text("result 2")
                    Text("result 3")
                }
            } else if url == nil {
                Welcome(url: $url)
            } else {
                WebView(url: $url).ignoresSafeArea(edges: .all)
            }
        }
        .modifier(BarModifiers())
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
    }
    
    @ViewBuilder
    var navigationButtons: some View {
        Button {
            viewModel.webView?.goBack()
        } label: { Image(systemName: "chevron.backward") }.disabled(!viewModel.canGoBack)
        Button {
            viewModel.webView?.goForward()
        } label: { Image(systemName: "chevron.forward") }.disabled(!viewModel.canGoForward)
    }
}

@available(macOS 12.0, iOS 16.0, *)
private struct BarModifiers: ViewModifier {
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
