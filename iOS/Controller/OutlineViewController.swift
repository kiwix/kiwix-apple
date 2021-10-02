//
//  OutlineViewController.swift
//  Kiwix
//
//  Created by Chris Li on 10/1/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

class OutlineViewController: UIHostingController<OutlineView> {
    convenience init(webView: WKWebView) {
        self.init(rootView: OutlineView(webView: webView))
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Done", style: .done, target: self, action: #selector(dismissController)
        )
    }
    
    @objc private func dismissController() {
        dismiss(animated: true)
    }
}

struct OutlineView: View {
    @ObservedObject var viewModel: ViewModel
    
    init(webView: WKWebView) {
        self.viewModel = ViewModel(webView: webView)
    }
    
    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                Text(item.text)
            }
        }.listStyle(PlainListStyle()).navigationBarTitle(viewModel.title)
    }
    
    class ViewModel: ObservableObject {
        @Published private(set) var title = "Outline"
        @Published private(set) var items = [OutlineItem]()
        
        private weak var webView: WKWebView?
        private var webViewURLObserver: NSKeyValueObservation?
        
        init(webView: WKWebView) {
            self.webView = webView
            webViewURLObserver = webView.observe(\.url, options: [.initial, .new]) { [unowned self] webView, _ in
                self.load(url: webView.url)
            }
        }
        
        private func load(url: URL?) {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let url = url, let parser = try? Parser(url: url) else { self.items = []; return }
                let items = parser.getOutlineItems()
                let h1Items = items.filter{ $0.level == 1 }
                DispatchQueue.main.async {
                    if h1Items.count == 1, let h1Item = h1Items.first {
                        self.title = h1Item.text
                        self.items = items.filter { $0.level != 1 }.map { item in
                            OutlineItem(index: item.index, text: item.text, level: item.level - 1)
                        }
                    } else {
                        self.title = "Outline"
                        self.items = items
                    }
                }
            }
        }
    }
}
