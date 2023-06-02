//
//  ReaderViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import MapKit
import WebKit

import Defaults

class ReadingViewModel: NSObject, ObservableObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var articleTitle: String = ""
    @Published var zimFileName: String = ""
    @Published var outlineItems = [OutlineItem]()
    @Published var outlineItemTree = [OutlineItem]()
    
    @Published var activeAlert: ActiveAlert?
    @Published var activeSheet: ActiveSheet?
    
    let webView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
    
    static let bookmarkNotificationName = NSNotification.Name(rawValue: "Bookmark.toggle")
    
    // MARK: - Navigation
    
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    
    // MARK: - Outline
    
    /// Scroll to a outline item
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
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "headings", let headings = message.body as? [[String: String]] {
            DispatchQueue.global(qos: .userInitiated).async {
                self.generateOutlineList(headings: headings)
                self.generateOutlineTree(headings: headings)
            }
        }
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
            switch Defaults[.externalLinkLoadingPolicy] {
            case .alwaysAsk:
                activeAlert = .externalLinkAsk(url: url)
            case .alwaysLoad:
                #if os(macOS)
                NSWorkspace.shared.open(url)
                #elseif os(iOS)
                activeSheet = .safari(url: url)
                #endif
            case .neverLoad:
                activeAlert = .externalLinkNotLoading
            }
            decisionHandler(.cancel)
        } else if url.scheme == "geo" {
            if FeatureFlags.map {
                let location: CLLocation? = {
                    let parts = url.absoluteString.replacingOccurrences(of: "geo:", with: "").split(separator: ",")
                    guard let latitudeString = parts.first,
                          let longitudeString = parts.last,
                          let latitude = Double(latitudeString),
                          let longitude = Double(longitudeString) else { return nil }
                    return CLLocation(latitude: latitude, longitude: longitude)
                }()
                #if os(macOS)
                navigationItem = .map(location: location)
                #elseif os(iOS)
                activeSheet = .map(location: location)
                #endif
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
        webView.applyTextSizeAdjustment()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let error = error as NSError
        guard error.code != NSURLErrorCancelled else { return }
        activeAlert = .articleFailedToLoad
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
                let openAction = UIAction(title: "Open", image: UIImage(systemName: "doc.richtext")) { _ in
                    webView.load(URLRequest(url: url))
                }
                actions.append(openAction)
                
                // bookmark
                let bookmarkAction: UIAction = {
                    let context = Database.shared.container.viewContext
                    let predicate = NSPredicate(format: "articleURL == %@", url as CVarArg)
                    let request = Bookmark.fetchRequest(predicate: predicate)
                    if let bookmarks = try? context.fetch(request), !bookmarks.isEmpty {
                        return UIAction(title: "Remove Bookmark", image: UIImage(systemName: "star.slash.fill")) { _ in
                            BookmarkOperations.delete(url, withNotification: false)
                        }
                    } else {
                        return UIAction(title: "Bookmark", image: UIImage(systemName: "star")) { _ in
                            BookmarkOperations.create(url, withNotification: false)
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
}
