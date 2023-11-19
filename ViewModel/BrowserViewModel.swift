//
//  BrowserViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 6/21/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import Combine
import CoreData
import CoreLocation
import WebKit

import OrderedCollections

class BrowserViewModel: NSObject, ObservableObject,
                        WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate,
                        NSFetchedResultsControllerDelegate
{
    static private var cache = OrderedDictionary<NSManagedObjectID, BrowserViewModel>()
    
    static func getCached(tabID: NSManagedObjectID) -> BrowserViewModel {
        let viewModel = cache[tabID] ?? BrowserViewModel(tabID: tabID)
        cache.removeValue(forKey: tabID)
        cache[tabID] = viewModel
        return viewModel
    }
    
    static func purgeCache() {
        guard cache.count > 10 else { return }
        let range = 0 ..< cache.count - 5
        cache.values[range].forEach { viewModel in
            viewModel.persistState()
        }
        cache.removeSubrange(range)
    }
    
    // MARK: - Properties
    
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var articleTitle: String = ""
    @Published private(set) var zimFileName: String = ""
    @Published private(set) var articleBookmarked = false
    @Published private(set) var outlineItems = [OutlineItem]()
    @Published private(set) var outlineItemTree = [OutlineItem]()
    @Published private(set) var url: URL?
    @Published var externalLink: URL?
    
    let tabID: NSManagedObjectID?
    let webView: WKWebView
    private var canGoBackObserver: NSKeyValueObservation?
    private var canGoForwardObserver: NSKeyValueObservation?
    private var titleURLObserver: AnyCancellable?
    private var bookmarkFetchedResultsController: NSFetchedResultsController<Bookmark>?
    
    // MARK: - Lifecycle
    
    init(tabID: NSManagedObjectID? = nil) {
        self.tabID = tabID
        self.webView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
        super.init()
        
        // restore webview state, and set url before observer call back
        // note: optionality of url determines what to show in a tab, so it should be set before tab is on screen
        if let tabID, let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab {
            webView.interactionState = tab.interactionState
            url = webView.url
        }
        
        // configure web view
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.defaultWebpagePreferences.preferredContentMode = .mobile  // for font adjustment to work
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "headings")
        webView.configuration.userContentController.add(self, name: "headings")
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // get outline items if something is already loaded
        if webView.url != nil {
            webView.evaluateJavaScript("getOutlineItems();")
        }
        
        // setup web view property observers
        canGoBackObserver = webView.observe(\.canGoBack, options: .initial) { [weak self] webView, _ in
            self?.canGoBack = webView.canGoBack
        }
        canGoForwardObserver = webView.observe(\.canGoForward, options: .initial) { [weak self] webView, _ in
            self?.canGoForward = webView.canGoForward
        }
        titleURLObserver = Publishers.CombineLatest(
            webView.publisher(for: \.title, options: .initial),
            webView.publisher(for: \.url, options: .initial)
        )
        .debounce(for: 0.1, scheduler: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        .sink { [weak self] title, url in
            let title: String? = {
                if let title, !title.isEmpty {
                    return title
                } else {
                    return nil
                }
            }()
            let zimFile: ZimFile? = {
                guard let url, let zimFileID = UUID(uuidString: url.host ?? "") else { return nil }
                return try? Database.viewContext.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first
            }()
            
            // update view model
            self?.articleTitle = title ?? ""
            self?.zimFileName = zimFile?.name ?? ""
            self?.url = url
            
            // update tab data
            if let tabID = self?.tabID,
               let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab,
               let title {
                tab.title = title
                tab.zimFile = zimFile
            }
            
            // setup bookmark fetched results controller
            self?.bookmarkFetchedResultsController = NSFetchedResultsController(
                fetchRequest: Bookmark.fetchRequest(predicate: {
                    if let url = url {
                        return NSPredicate(format: "articleURL == %@", url as CVarArg)
                    } else {
                        return NSPredicate(format: "articleURL == nil")
                    }
                }()),
                managedObjectContext: Database.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            self?.bookmarkFetchedResultsController?.delegate = self
            try? self?.bookmarkFetchedResultsController?.performFetch()
        }
    }
    
    func updateLastOpened() {
        guard let tabID, let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab else { return }
        tab.lastOpened = Date()
    }
    
    func persistState() {
        guard let tabID, let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab else { return }
        tab.interactionState = webView.interactionState as? Data
        try? Database.viewContext.save()
    }
    
    // MARK: - Content Loading
    
    func load(url: URL) {
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }
    
    func loadRandomArticle(zimFileID: UUID? = nil) {
        let zimFileID = zimFileID ?? UUID(uuidString: webView.url?.host ?? "")
        guard let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
        load(url: url)
    }
    
    func loadMainArticle(zimFileID: UUID? = nil) {
        let zimFileID = zimFileID ?? UUID(uuidString: webView.url?.host ?? "")
        guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
        load(url: url)
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
            externalLink = url
            decisionHandler(.cancel)
        } else if url.scheme == "geo" {
            if FeatureFlags.map {
                let _: CLLocation? = {
                    let parts = url.absoluteString.replacingOccurrences(of: "geo:", with: "").split(separator: ",")
                    guard let latitudeString = parts.first,
                          let longitudeString = parts.last,
                          let latitude = Double(latitudeString),
                          let longitude = Double(longitudeString) else { return nil }
                    return CLLocation(latitude: latitude, longitude: longitude)
                }()
            } else {
                let coordinate = url.absoluteString.replacingOccurrences(of: "geo:", with: "")
                if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate)") {
                    #if os(macOS)
                    NSWorkspace.shared.open(url)
                    #elseif os(iOS)
                    UIApplication.shared.open(url)
                    #endif
                }
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItems();")
        #if os(iOS)
        webView.adjustTextSize()
        #endif
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let error = error as NSError
        guard error.code != NSURLErrorCancelled else { return }
        NotificationCenter.default.post(
            name: .alert, object: nil, userInfo: ["rawValue": ActiveAlert.articleFailedToLoad.rawValue]
        )
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "headings", let headings = message.body as? [[String: String]] {
            DispatchQueue.global(qos: .userInitiated).async {
                self.generateOutlineList(headings: headings)
                self.generateOutlineTree(headings: headings)
            }
        }
    }
    
    // MARK: - WKUIDelegate
    
    #if os(iOS)
    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        guard let url = elementInfo.linkURL, url.isKiwixURL else { completionHandler(nil); return }
        let configuration = UIContextMenuConfiguration(
            previewProvider: {
                let webView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
                webView.load(URLRequest(url: url))
                return WebViewController(webView: webView)
            }, actionProvider: { suggestedActions in
                var actions = [UIAction]()
                
                // open url
                actions.append(
                    UIAction(title: "Open", image: UIImage(systemName: "doc.text")) { _ in
                        webView.load(URLRequest(url: url))
                    }
                )
                actions.append(
                    UIAction(title: "Open in New Tab", image: UIImage(systemName: "doc.badge.plus")) { _ in
                        NotificationCenter.openURL(url, inNewTab: true)
                    }
                )

                // bookmark
                let bookmarkAction: UIAction = {
                    let context = Database.viewContext
                    let predicate = NSPredicate(format: "articleURL == %@", url as CVarArg)
                    let request = Bookmark.fetchRequest(predicate: predicate)
                    if let bookmarks = try? context.fetch(request), !bookmarks.isEmpty {
                        return UIAction(title: "Remove Bookmark", image: UIImage(systemName: "star.slash.fill")) { _ in
                            self.deleteBookmark(url: url)
                        }
                    } else {
                        return UIAction(title: "Bookmark", image: UIImage(systemName: "star")) { _ in
                            self.createBookmark(url: url)
                        }
                    }
                }()
                actions.append(bookmarkAction)
                
                return UIMenu(children: actions)
            }
        )
        completionHandler(configuration)
    }
    #endif
    
    // MARK: - Bookmark
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        articleBookmarked = !snapshot.itemIdentifiers.isEmpty
    }
    
    func createBookmark(url: URL? = nil) {
        guard let url = url ?? webView.url else { return }
        Database.performBackgroundTask { context in
            let bookmark = Bookmark(context: context)
            bookmark.articleURL = url
            bookmark.created = Date()
            if let parser = try? HTMLParser(url: url) {
                bookmark.title = parser.title ?? ""
                bookmark.snippet = parser.getFirstSentence(languageCode: nil)?.string
                guard let zimFileID = UUID(uuidString: url.host ?? ""),
                      let zimFile = try? context.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first else { return }
                bookmark.zimFile = zimFile
                if let imagePath = parser.getFirstImagePath() {
                    bookmark.thumbImageURL = URL(zimFileID: zimFileID.uuidString, contentPath: imagePath)
                }
            }
            try? context.save()
        }
    }
    
    func deleteBookmark(url: URL? = nil) {
        guard let url = url ?? webView.url else { return }
        Database.performBackgroundTask { context in
            let request = Bookmark.fetchRequest(predicate: NSPredicate(format: "articleURL == %@", url as CVarArg))
            guard let bookmark = try? context.fetch(request).first else { return }
            context.delete(bookmark)
            try? context.save()
        }
    }
    
    // MARK: - Outline
    
    /// Scroll to an outline item
    /// - Parameter outlineItemID: ID of the outline item to scroll to
    func scrollTo(outlineItemID: String) {
        webView.evaluateJavaScript("scrollToHeading('\(outlineItemID)')")
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
