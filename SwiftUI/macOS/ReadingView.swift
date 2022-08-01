//
//  ReadingView.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

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
            ToolbarItemGroup(placement: .navigation) {
                ControlGroup {
                    Button {
                        viewModel.webView.goBack()
                    } label: { Image(systemName: "chevron.backward") }.disabled(!viewModel.canGoBack)
                    Button {
                        viewModel.webView.goForward()
                    } label: { Image(systemName: "chevron.forward") }.disabled(!viewModel.canGoForward)
                }
            }
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
}

enum ReadingViewNavigationAction: Equatable {
    case goBack, goForward, outlineItem(id: String)
}

class ReadingViewModel: NSObject, ObservableObject, WKScriptMessageHandler {
    @Published var articleTitle = ""
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var outlineItems: [OutlineItem] = []
    
    var webView: WKWebView?
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "headings", let headings = message.body as? [[String: String]] {
            DispatchQueue.global(qos: .userInitiated).async {
                let allLevels = headings.compactMap { Int($0["tag"]?.suffix(1) ?? "") }
                let offset = allLevels.filter({ $0 == 1 }).count == 1 ? 2 : allLevels.min() ?? 0
                let outlineItems: [OutlineItem] = headings.enumerated().compactMap { index, heading in
                    guard let id = heading["id"],
                          let text = heading["text"],
                          let tag = heading["tag"],
                          let level = Int(tag.suffix(1)) else { return nil }
                    return OutlineItem(id: id, index: index, text: text, level: max(level - offset, 0))
                }
                DispatchQueue.main.async {
                    self.outlineItems = outlineItems
                }
            }
        }
    }
    
    /// Scroll to a outline item
    /// - Parameter outlineItemID: ID of the outline item to scroll to
    func scrollTo(outlineItemID: String) {
        webView?.evaluateJavaScript("scrollToHeading('\(outlineItemID)')")
    }
}
