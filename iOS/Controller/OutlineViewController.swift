//
//  OutlineViewController.swift
//  Kiwix
//
//  Created by Chris Li on 10/1/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit
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
    
    var outlineItemSelected: (OutlineItem) -> Void = { _ in }
    
    init(webView: WKWebView) {
        self.viewModel = ViewModel(webView: webView)
    }
    
    var body: some View {
        TableView(items: viewModel.items, outlineItemSelected: outlineItemSelected)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle(viewModel.title)
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
    
    struct TableView: UIViewRepresentable {
        let items: [OutlineItem]
        let outlineItemSelected: (OutlineItem) -> Void
        
        func makeUIView(context: Context) -> UITableView {
            let tableView = UITableView(frame: .zero)
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            tableView.separatorInsetReference = .fromAutomaticInsets
            tableView.dataSource = context.coordinator
            tableView.delegate = context.coordinator
            return tableView
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(outlineItemSelected: outlineItemSelected)
        }
        
        func updateUIView(_ tableView: UITableView, context: Context) {
            context.coordinator.items = items
            tableView.reloadData()
        }
        
        class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
            let outlineItemSelected: (OutlineItem) -> Void
            var items: [OutlineItem] = []
            
            init(outlineItemSelected: @escaping (OutlineItem) -> Void) {
                self.outlineItemSelected = outlineItemSelected
            }
            
            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                items.count
            }
            
            func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = items[indexPath.row].text
                cell.separatorInset =  UIEdgeInsets(
                    top: 0, left: 25 * CGFloat(items[indexPath.row].level - 1), bottom: 0, right: 0
                )
                return cell
            }
            
            func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                tableView.deselectRow(at: indexPath, animated: true)
                outlineItemSelected(items[indexPath.row])
            }
        }
    }
}
