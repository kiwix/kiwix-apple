//
//  ReadingView.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

@available(macOS 12.0, iOS 15.0, *)
struct ReadingView: View {
    @Binding var url: URL?
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject var viewModel: ReaderViewModel
    
    var body: some View {
        WebView(
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
        .navigationTitle(viewModel.articleTitle)
        .toolbar {
            #if os(macOS)
            ToolbarItemGroup(placement: .navigation) { ControlGroup { navigationButtons } }
            #elseif os(iOS)
            ToolbarItemGroup(placement: .navigationBarLeading) {
                navigationButtons
            }
            #endif
            ToolbarItemGroup {
                Button {
                    
                } label: {
                    Image(systemName: "star")
                }
                Menu {
                    ForEach(viewModel.outlineItems) { item in
                        Button(String(repeating: "    ", count: item.level) + item.text) {
                            viewModel.scrollTo(outlineItemID: item.id)
                        }
                    }
                } label: {
                    Image(systemName: "list.bullet")
                }.disabled(viewModel.outlineItems.isEmpty)
                Button {
                    
                } label: {
                    Image(systemName: "house")
                }
                Button {
                    
                } label: {
                    Image(systemName: "die.face.5")
                }
            }
        }
    }
    
    @ViewBuilder
    var navigationButtons: some View {
        Button {
            viewModel.webView.goBack()
        } label: { Image(systemName: "chevron.backward") }.disabled(!viewModel.canGoBack)
        Button {
            viewModel.webView.goForward()
        } label: { Image(systemName: "chevron.forward") }.disabled(!viewModel.canGoForward)
    }
}

struct ReadingView_iOS14: View {
    @Binding var url: URL?
    @EnvironmentObject var viewModel: ReaderViewModel
    
    var body: some View {
        WebView(
            url: $url
        )
    }
}
