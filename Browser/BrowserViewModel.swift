//
//  BrowserViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 6/21/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI
import WebKit

class BrowserViewModel: NSObject, ObservableObject,
                        WKNavigationDelegate, WKScriptMessageHandler,
                        NSFetchedResultsControllerDelegate
{
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var articleTitle: String = ""
    @Published private(set) var zimFileName: String = ""
    @Published private(set) var articleBookmarked = false
    @Published private(set) var outlineItems = [OutlineItem]()
    @Published private(set) var outlineItemTree = [OutlineItem]()
    @Published private(set) var url: URL?
    
    private(set) var tabID: NSManagedObjectID?
    private(set) var webView: WKWebView?
    private var canGoBackObserver: NSKeyValueObservation?
    private var canGoForwardObserver: NSKeyValueObservation?
    private var titleObserver: NSKeyValueObservation?
    private var urlObserver: NSKeyValueObservation?
    private var bookmarkFetchedResultsController: NSFetchedResultsController<Bookmark>?
    
    func configure(tabID: NSManagedObjectID?, webView: WKWebView) {
        self.tabID = tabID
        self.webView = webView
        
        // configure web view
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.defaultWebpagePreferences.preferredContentMode = .mobile  // for font adjustment to work
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "headings")
        webView.configuration.userContentController.add(self, name: "headings")
        webView.navigationDelegate = self
        
        // setup web view property observers
        canGoBackObserver = webView.observe(\.canGoBack, options: .initial) { [unowned self] webView, _ in
            canGoBack = webView.canGoBack
        }
        canGoForwardObserver = webView.observe(\.canGoForward, options: .initial) { [unowned self] webView, _ in
            canGoForward = webView.canGoForward
        }
        titleObserver = webView.observe(\.title, options: .initial) { [unowned self] webView, _ in
            guard let zimFileID = UUID(uuidString: webView.url?.host ?? ""),
                  let title = webView.title,
                  !title.isEmpty else { return }
            Database.performBackgroundTask { context in
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                guard let tabID = self.tabID,
                      let tab = try? context.existingObject(with: tabID) as? Tab else { return }
                tab.title = title
                if let zimFile = try? context.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first {
                    tab.zimFile = zimFile
                }
                try? context.save()
                DispatchQueue.main.async {
                    self.articleTitle = title
                    self.zimFileName = tab.zimFile?.name ?? ""
                }
            }
        }
        urlObserver = webView.observe(\.url, options: .initial) { [unowned self] webView, _ in
            url = webView.url
            let fetchRequest = Bookmark.fetchRequest(predicate: {
                if let url = webView.url {
                    return NSPredicate(format: "articleURL == %@", url as CVarArg)
                } else {
                    return NSPredicate(format: "articleURL == nil")
                }
            }())
            bookmarkFetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: Database.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            bookmarkFetchedResultsController?.delegate = self
            try? bookmarkFetchedResultsController?.performFetch()
        }
    }
    
    // MARK: - Content Loading
    
    func load(url: URL) {
        guard webView?.url != url else { return }
        webView?.load(URLRequest(url: url))
    }
    
    func loadRandomArticle(zimFileID: UUID? = nil) {
        let zimFileID = zimFileID ?? UUID(uuidString: webView?.url?.host ?? "")
        guard let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
        load(url: url)
    }
    
    func loadMainArticle(zimFileID: UUID? = nil) {
        let zimFileID = zimFileID ?? UUID(uuidString: webView?.url?.host ?? "")
        guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
        load(url: url)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItems();")
        webView.applyTextSizeAdjustment()
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
    
    // MARK: - Bookmark
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        articleBookmarked = !snapshot.itemIdentifiers.isEmpty
    }
    
    func createBookmark() {
        guard let url = webView?.url else { return }
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
    
    func deleteBookmark() {
        guard let url = webView?.url else { return }
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
        webView?.evaluateJavaScript("scrollToHeading('\(outlineItemID)')")
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
