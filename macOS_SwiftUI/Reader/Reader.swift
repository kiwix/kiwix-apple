//
//  Reader.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import CoreData
import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct Reader: View {
    @StateObject var viewModel = ReaderViewModel()
    @State var url: URL?
    @FetchRequest(sortDescriptors: []) private var onDeviceZimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        NavigationView {
            Sidebar(url: $url)
                .frame(minWidth: 250)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { Kiwix.toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
                    }
                }
            WebView(url: $url, webView: viewModel.webView)
                .ignoresSafeArea(.container, edges: .vertical)
                .frame(minWidth: 400, idealWidth: 800, minHeight: 500, idealHeight: 550)
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button { viewModel.webView.goBack() } label: {
                            Image(systemName: "chevron.backward")
                        }.disabled(!viewModel.canGoBack)
                        Button { viewModel.webView.goForward() } label: {
                            Image(systemName: "chevron.forward")
                        }.disabled(!viewModel.canGoForward)
                    }
                    ToolbarItemGroup {
                        BookmarkButton(url: $url)
                        Button {
                            viewModel.loadMainPage()
                        } label: {
                            Image(systemName: "house")
                        }
                        .disabled(onDeviceZimFiles.isEmpty)
                        Menu {
                            ForEach(onDeviceZimFiles) { zimFile in
                                Button(zimFile.name) { viewModel.loadRandomPage(zimFileID: zimFile.id) }
                            }
                        } label: {
                            Label("Random Page", systemImage: "die.face.5")
                        } primaryAction: {
                            guard let zimFile = onDeviceZimFiles.first else { return }
                            viewModel.loadRandomPage(zimFileID: zimFile.fileID)
                        }.disabled(onDeviceZimFiles.isEmpty)
                    }
                }
        }
        .environmentObject(viewModel)
        .focusedSceneValue(\.readerViewModel, viewModel)
        .navigationTitle(viewModel.articleTitle)
        .navigationSubtitle(viewModel.zimFileName)
    }
}

class ReaderViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    @Published private(set) var canGoBack: Bool = false
    @Published private(set) var canGoForward: Bool = false
    @Published private(set) var articleTitle: String = ""
    @Published private(set) var zimFileName: String = ""
    @Published private(set) var outlineItems = [OutlineItem]()
    @Published var selectedOutlineItemID: String?
    
    private var allOutlineItems = [String: OutlineItem]()
    
    let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.userContentController = {
            let controller = WKUserContentController()
            guard FeatureFlags.wikipediaDarkUserCSS,
                  let path = Bundle.main.path(forResource: "wikipedia_dark", ofType: "css"),
                  let css = try? String(contentsOfFile: path) else { return controller }
            let source = """
                var style = document.createElement('style');
                style.innerHTML = `\(css)`;
                document.head.appendChild(style);
                """
            let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            controller.addUserScript(script)
            if let url = Bundle.main.url(forResource: "injection", withExtension: "js"),
               let javascript = try? String(contentsOf: url) {
                let script = WKUserScript(source: javascript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                controller.addUserScript(script)
            }
            return controller
        }()
        return WKWebView(frame: .zero, configuration: config)
    }()
    private var canGoBackObserver: NSKeyValueObservation?
    private var canGoForwardObserver: NSKeyValueObservation?
    private var titleObserver: NSKeyValueObservation?
    private var selectedOutlineItemObserver: AnyCancellable?
    
    override init() {
        super.init()
        webView.navigationDelegate = self
        canGoBackObserver = webView.observe(\.canGoBack) { [unowned self] webView, _ in
            self.canGoBack = webView.canGoBack
        }
        canGoForwardObserver = webView.observe(\.canGoForward) { [unowned self] webView, _ in
            self.canGoForward = webView.canGoForward
        }
        titleObserver = webView.observe(\.title) { [unowned self] webView, _ in
            guard let title = webView.title, !title.isEmpty,
                  let zimFileID = webView.url?.host,
                  let zimFile = try? Database.shared.container.viewContext.fetch(
                    ZimFile.fetchRequest(predicate: NSPredicate(format: "fileID == %@", zimFileID))
                  ).first else { return }
            self.articleTitle = title
            self.zimFileName = zimFile.name
        }
        selectedOutlineItemObserver = $selectedOutlineItemID.sink { [unowned self] selectedID in
            guard let selectedID = selectedID else { return }
            self.scrollTo(outlineItemID: selectedID)
        }
        
        webView.configuration.userContentController.add(self, name: "headings")
        webView.configuration.userContentController.add(self, name: "headingVisible")
    }
    
    func loadMainPage(zimFileID: UUID? = nil) {
        let zimFileID = zimFileID?.uuidString ?? webView.url?.host ?? ""
        guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
        webView.load(URLRequest(url: url))
    }
    
    func loadRandomPage(zimFileID: UUID? = nil) {
        let zimFileID = zimFileID?.uuidString ?? webView.url?.host ?? ""
        guard let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
        webView.load(URLRequest(url: url))
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else { return .cancel }
        if url.isKiwixURL, let redirectedURL = ZimFileService.shared.getRedirectedURL(url: url) {
            DispatchQueue.main.async { webView.load(URLRequest(url: redirectedURL)) }
            return .cancel
        } else if url.isKiwixURL {
            return .allow
        } else if url.scheme == "http" || url.scheme == "https" {
            DispatchQueue.main.async { NSWorkspace.shared.open(url) }
            return .cancel
        } else if url.scheme == "geo" {
            let coordinate = url.absoluteString.replacingOccurrences(of: "geo:", with: "")
            if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate)") {
                DispatchQueue.main.async { NSWorkspace.shared.open(url) }
            }
            return .cancel
        } else {
            return .cancel
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItem()")
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "headings", let headings = message.body as? [[String: String]] {
            DispatchQueue.global(qos: .userInitiated).async {
                self.generateOutlineTree(headings: headings)
            }
        } else if message.name == "headingVisible", let data = message.body as? [String: String] {
            selectedOutlineItemID = data["id"]
            allOutlineItems[data["id"]!]?.isExpanded = true
        }
    }
    
    // MARK: - Outlines
    
    private func scrollTo(outlineItemID: String) {
        let javascript = """
        element = document.getElementById('\(outlineItemID)')
        element.scrollIntoView({block: 'start', inline: 'start', behavior: 'smooth'})
        """
        webView.evaluateJavaScript(javascript)
    }
    
    /// Convert flattened heading element data to a tree of OutlineItems.
    /// - Parameter headings: list of heading element data retrieved from webview
    private func generateOutlineTree(headings: [[String: String]]) {
        let root = OutlineItem(index: -1, text: "", level: 0)
        var stack: [OutlineItem] = [root]
        var all = [String: OutlineItem]()
        
        headings.enumerated().forEach { index, heading in
            guard let id = heading["id"],
                  let text = heading["text"],
                  let tag = heading["tag"], let level = Int(tag.suffix(1)) else { return }
            let item = OutlineItem(id: id, index: index, text: text, level: level)
            all[item.id] = item
            
            // get last item in stack
            // if last item is child of item's sibling, unwind stack until a sibling is found
            guard var lastItem = stack.last else { return }
            while lastItem.level > item.level {
                stack.removeLast()
                lastItem = stack[stack.count - 1]
            }
            
            // if item is last item's sibling, add item to parent and replace last item with itself in stack
            // if item is last item's child, add item to parent and add item to stack
            if lastItem.level == item.level {
                stack[stack.count - 2].addChild(item)
                stack[stack.count - 1] = item
            } else if lastItem.level < item.level {
                stack[stack.count - 1].addChild(item)
                stack.append(item)
            }
        }
        
        // if there is only one h1, flatten one level
        if let rootChildren = root.children, rootChildren.count == 1, let rootFirstChild = rootChildren.first {
            let children = rootFirstChild.removeAllChildren()
            DispatchQueue.main.async {
                self.outlineItems = [rootFirstChild] + children
                self.allOutlineItems = all
            }
        } else {
            DispatchQueue.main.async {
                self.outlineItems = root.children ?? []
                self.allOutlineItems = [:]
            }
        }
    }
}
