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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if splitViewController != nil {
            navigationController?.navigationBar.isHidden = true
            rootView.viewModel.showTitleInList = true
        }
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
        if #available(iOS 14.0, *) {
            content.toolbar {
                ToolbarItem(placement: .principal) {
                    if let title = viewModel.title {
                        Button { outlineItemSelected(title) } label: {
                            Text(title.text).fontWeight(.semibold).foregroundColor(.primary)
                        }
                    } else {
                        Text("Outline").fontWeight(.semibold)
                    }
                }
            }
        } else {
            content.navigationBarTitle(viewModel.title?.text ?? "Outline")
        }
    }
    
    @ViewBuilder
    var content: some View {
        if let items = viewModel.items, items.isEmpty {
            VStack(spacing: 30) {
                ZStack {
                    Image(systemName: "list.bullet")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(20)
                        .foregroundColor(.secondary)
                    Circle().foregroundColor(.secondary).opacity(0.2)
                }.frame(width: 75, height: 75, alignment: .center)
                Text("Table of content not available.").font(Font.headline)
            }
        } else if let items = viewModel.items {
            TableView(items: items, outlineItemSelected: outlineItemSelected)
                .edgesIgnoringSafeArea(.bottom)
        } else {
            EmptyView()
        }
    }
    
    class ViewModel: ObservableObject {
        @Published private(set) var title: OutlineItem?
        @Published private(set) var items: [OutlineItem]?
        var showTitleInList = false
        
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
                    // When there is only one h1, that's usually the title.
                    // We show it either centered or in navigation bar.
                    if h1Items.count == 1, self.showTitleInList {
                        self.title = nil
                        self.items = items.map { item in
                            OutlineItem(index: item.index, text: item.text, level: item.level - 1)
                        }
                    } else if h1Items.count == 1, let h1Item = h1Items.first {
                        self.title = h1Item
                        self.items = items.filter { $0.level != 1 }.map { item in
                            OutlineItem(index: item.index, text: item.text, level: item.level - 1)
                        }
                    } else {
                        let offset = items.map{ $0.level }.min() ?? 1
                        self.title = nil
                        self.items = items.map { item in
                            OutlineItem(index: item.index, text: item.text, level: item.level - offset + 1)
                        }
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
                let item = items[indexPath.row]
                cell.textLabel?.text = item.text
                cell.textLabel?.textAlignment = item.level == 0 ? .center : .natural
                cell.separatorInset =  UIEdgeInsets(
                    top: 0, left: max(0, 20 * CGFloat(item.level - 1)), bottom: 0, right: 0
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
