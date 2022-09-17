//
//  ReaderViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import WebKit

import Defaults

class ReadingViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var articleTitle: String = ""
    @Published var zimFileName: String = ""
    @Published var outlineItems = [OutlineItem]()
    @Published var outlineItemTree = [OutlineItem]()
    
    var webViewInteractionState: Any?
    var webViews = Set<WKWebView>()
    
    static let bookmarkNotificationName = NSNotification.Name(rawValue: "Bookmark.toggle")
    
    // MARK: - delegates
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isKiwixURL, let redirectedURL = ZimFileService.shared.getRedirectedURL(url: url) {
            DispatchQueue.main.async { webView.load(URLRequest(url: redirectedURL)) }
            decisionHandler(.cancel)
        } else if url.isKiwixURL {
            decisionHandler(.allow)
        } else if url.scheme == "http" || url.scheme == "https" {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #elseif os(iOS)
            // show external article load alert
            #endif
            decisionHandler(.cancel)
        } else if url.scheme == "geo" {
            let coordinate = url.absoluteString.replacingOccurrences(of: "geo:", with: "")
            if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate)") {
                #if os(macOS)
                NSWorkspace.shared.open(url)
                #elseif os(iOS)
                UIApplication.shared.open(url)
                #endif
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItems();")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "headings", let headings = message.body as? [[String: String]] {
            DispatchQueue.global(qos: .userInitiated).async {
                self.generateOutlineList(headings: headings)
                self.generateOutlineTree(headings: headings)
            }
        }
    }
    
    // MARK: - navigation
    
    func goBack() {
        webViews.first?.goBack()
    }
    
    func goForward() {
        webViews.first?.goForward()
    }
    
    // MARK: - bookmark
    
    /// Create bookmark for an article
    /// - Parameter url: url of the article to bookmark
    static func createBookmark(_ url: URL?) {
        guard let url = url else { return }
        let context = Database.shared.container.viewContext
        let bookmark = Bookmark(context: context)
        DispatchQueue.global().sync {
            bookmark.articleURL = url
            bookmark.created = Date()
            if let parser = try? HTMLParser(url: url) {
                bookmark.title = parser.title ?? ""
                bookmark.snippet = parser.getFirstSentence(languageCode: nil)?.string
                guard let zimFileID = url.host,
                      let zimFileID = UUID(uuidString: zimFileID),
                      let zimFile = try? context.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first else { return }
                bookmark.zimFile = zimFile
                if let imagePath = parser.getFirstImagePath() {
                    bookmark.thumbImageURL = URL(zimFileID: zimFileID.uuidString, contentPath: imagePath)
                }
            }
        }
        try? context.save()
        NotificationCenter.default.post(name: ReadingViewModel.bookmarkNotificationName, object: url)
    }
    
    /// Delete an article bookmark
    /// - Parameter url: url of the article to delete bookmark
    static func deleteBookmark(_ url: URL?) {
        guard let url = url else { return }
        let context = Database.shared.container.viewContext
        let request = Bookmark.fetchRequest(predicate: NSPredicate(format: "articleURL == %@", url as CVarArg))
        guard let bookmark = try? context.fetch(request).first else { return }
        context.delete(bookmark)
        try? context.save()
        NotificationCenter.default.post(name: ReaderViewModel.bookmarkNotificationName, object: nil)
    }
    
    // MARK: - outline
    
    /// Scroll to a outline item
    /// - Parameter outlineItemID: ID of the outline item to scroll to
    func scrollTo(outlineItemID: String) {
        webViews.first?.evaluateJavaScript("scrollToHeading('\(outlineItemID)')")
    }
    
    /// Convert flattened heading element data to a list of OutlineItems.
    /// - Parameter headings: list of heading element data retrieved from webview
    private func generateOutlineList(headings: [[String: String]]) {
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
                self.outlineItemTree = [rootFirstChild] + children
            }
        } else {
            DispatchQueue.main.async {
                self.outlineItemTree = root.children ?? []
            }
        }
    }
}

enum ActiveSheet: String, Identifiable {
    var id: String { rawValue }
    case outline, bookmarks, library, settings
}

class ReaderViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    @Published private(set) var canGoBack: Bool = false
    @Published private(set) var canGoForward: Bool = false
    @Published private(set) var articleTitle: String = ""
    @Published private(set) var zimFileName: String = ""
    @Published private(set) var outlineItems = [OutlineItem]()
    
    static let bookmarkNotificationName = NSNotification.Name(rawValue: "Bookmark.toggle")
    
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
    private var pageZoomObserver: Defaults.Observation?
    
    override init() {
        super.init()
        webView.allowsBackForwardNavigationGestures = true
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
        pageZoomObserver = Defaults.observe(.webViewPageZoom) { change in
            self.webView.pageZoom = change.newValue
        }
        
        webView.configuration.userContentController.add(self, name: "headings")
        webView.configuration.userContentController.add(self, name: "headingVisible")
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isKiwixURL, let redirectedURL = ZimFileService.shared.getRedirectedURL(url: url) {
            DispatchQueue.main.async { webView.load(URLRequest(url: redirectedURL)) }
            decisionHandler(.cancel)
        } else if url.isKiwixURL {
            decisionHandler(.allow)
        } else if url.scheme == "http" || url.scheme == "https" {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #elseif os(iOS)
            // show external article load alert
            #endif
            decisionHandler(.cancel)
        } else if url.scheme == "geo" {
            let coordinate = url.absoluteString.replacingOccurrences(of: "geo:", with: "")
            if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate)") {
                #if os(macOS)
                NSWorkspace.shared.open(url)
                #elseif os(iOS)
                UIApplication.shared.open(url)
                #endif
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItems();")
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "headings", let headings = message.body as? [[String: String]] {
            DispatchQueue.global(qos: .userInitiated).async {
                self.generateOutlineList(headings: headings)
//                self.generateOutlineTree(headings: headings)
            }
        }
    }
    
    // MARK: - Bookmark
    
    func createBookmark() {
        guard let url = webView.url else { return }
        Database.shared.container.performBackgroundTask { context in
            let bookmark = Bookmark(context: context)
            bookmark.articleURL = url
            bookmark.title = self.articleTitle
            bookmark.created = Date()
            if let parser = try? HTMLParser(url: url) {
                bookmark.snippet = parser.getFirstSentence(languageCode: nil)?.string
                if let zimFileID = url.host, let imagePath = parser.getFirstImagePath() {
                    bookmark.thumbImageURL = URL(zimFileID: zimFileID, contentPath: imagePath)
                }
            }
            try? context.save()
        }
        NotificationCenter.default.post(name: ReaderViewModel.bookmarkNotificationName, object: url)
    }
    
    func deleteBookmark() {
        guard let url = webView.url else { return }
        Database.shared.container.performBackgroundTask { context in
            let request = Bookmark.fetchRequest(predicate: NSPredicate(format: "articleURL == %@", url as CVarArg))
            guard let bookmark = try? context.fetch(request).first else { return }
            context.delete(bookmark)
            try? context.save()
        }
        NotificationCenter.default.post(name: ReaderViewModel.bookmarkNotificationName, object: nil)
    }
    
    // MARK: - Outlines
    
    /// Scroll to a outline item
    /// - Parameter outlineItemID: ID of the outline item to scroll to
    func scrollTo(outlineItemID: String) {
        webView.evaluateJavaScript("scrollToHeading('\(outlineItemID)')")
    }
    
    private func generateOutlineList(headings: [[String: String]]) {
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
            }
        } else {
            DispatchQueue.main.async {
                self.outlineItems = root.children ?? []
            }
        }
    }
}
