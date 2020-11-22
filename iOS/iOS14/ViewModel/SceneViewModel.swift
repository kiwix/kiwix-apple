//
//  SceneViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 10/24/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

@available(iOS 14.0, *)
enum ContentMode {
    case home, web, transition
}

@available(iOS 14.0, *)
enum SidebarContentMode {
    case bookmark, outline
}

@available(iOS 14.0, *)
enum SheetContentMode {
    case bookmark, outline
}

@available(iOS 14.0, *)
class SceneViewModel: NSObject, ObservableObject, UISplitViewControllerDelegate, WKNavigationDelegate {
    let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: config)
    }()
    
    @Published private(set) var contentDisplayMode = ContentMode.home
    
    @Published var isSidebarVisible = false
    private(set) var shouldAutoHideSidebar = false
    
    @Published private(set) var sidebarContentMode = SidebarContentMode.outline
    @Published private(set) var sheetContentMode = SheetContentMode.outline
    
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var currentArticleURL: URL?
    @Published private(set) var currentArticleOutlineItems: [OutlineItem]?
    
    override init() {
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }
    
    // MARK: - Actions
    
    func load(url: URL) {
        if contentDisplayMode == .home {
            withAnimation(.easeIn(duration: 0.1)) { contentDisplayMode = .transition }
        }
        webView.load(URLRequest(url: url))
    }
    
    func loadMainPage(zimFile: ZimFile) {
        guard let mainPageURL = ZimMultiReader.shared.getMainPageURL(zimFileID: zimFile.id) else { return }
        load(url: mainPageURL)
    }
    
    func houseButtonTapped() {
        withAnimation(Animation.easeInOut(duration: 0.2)) {
            contentDisplayMode = contentDisplayMode == .home ? .web : .home
        }
    }
    
    func navigateToOutlineItem(index: Int) {
        webView.evaluateJavaScript("outlines.scrollToView(\(index))")
    }
    
    func showSidebar(content: SidebarContentMode?) {
        isSidebarVisible = true
        if let content = content { sidebarContentMode = content }
    }
    
    func hideSidebar() {
        isSidebarVisible = false
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ svc: UISplitViewController, willShow column: UISplitViewController.Column) {
        guard column == .primary, UIApplication.shared.applicationState == .active else { return }
        showSidebar(content: nil)
    }

    func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column) {
        guard column == .primary, UIApplication.shared.applicationState == .active else { return }
        hideSidebar()
    }
    
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        if displayMode == .oneOverSecondary {
            shouldAutoHideSidebar = true
        } else {
            shouldAutoHideSidebar = false
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isKiwixURL {
            guard let zimFileID = url.host else { decisionHandler(.cancel); return }
            if let redirectedPath = ZimMultiReader.shared.getRedirectedPath(zimFileID: zimFileID, contentPath: url.path),
                let redirectedURL = URL(zimFileID: zimFileID, contentPath: redirectedPath) {
                decisionHandler(.cancel)
                webView.load(URLRequest(url: redirectedURL))
            } else {
                decisionHandler(.allow)
            }
        } else if url.scheme == "http" || url.scheme == "https" {
//            let policy = Defaults[.externalLinkLoadingPolicy]
//            if policy == .alwaysLoad {
//                let controller = SFSafariViewController(url: url)
//                self.present(controller, animated: true, completion: nil)
//            } else {
//                present(UIAlertController.externalLink(policy: policy, action: {
//                    let controller = SFSafariViewController(url: url)
//                    self.present(controller, animated: true, completion: nil)
//                }), animated: true)
//            }
            decisionHandler(.cancel)
        } else if url.scheme == "geo" {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if contentDisplayMode == .transition {
            withAnimation(.easeOut(duration: 0.1)) { contentDisplayMode = .web }
        }
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        currentArticleURL = webView.url
        
        guard let url = Bundle.main.url(forResource: "Inject", withExtension: "js"),
              let javascript = try? String(contentsOf: url) else { return }
        webView.evaluateJavaScript(javascript)
        webView.evaluateJavaScript("outlines.getHeadingObjects()", completionHandler: { [weak self] (results, error) in
            guard let results = results as? [[String: Any]] else { return }
            self?.currentArticleOutlineItems = results.compactMap({ OutlineItem(rawValue: $0) })
        })
    }
}

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}
