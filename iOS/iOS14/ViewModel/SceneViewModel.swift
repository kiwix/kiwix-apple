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
enum ContentDisplayMode {
    case homeView, webView, transitionView
}

@available(iOS 14.0, *)
class SceneViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: config)
    }()
    
    @Published private(set) var contentDisplayMode = ContentDisplayMode.homeView
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var currentArticleURL: URL?
    @Published private(set) var currentArticleOutlineItems: [OutlineItem]?
    
    @Published var currentExternalURL: URL?
    
    override init() {
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }
    
    // MARK: - Actions
    
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    
    func load(url: URL) {
        if contentDisplayMode == .homeView {
            withAnimation(.easeIn(duration: 0.1)) { contentDisplayMode = .transitionView }
        }
        webView.load(URLRequest(url: url))
    }
    
    func loadMainPage(zimFile: ZimFile) {
        guard let mainPageURL = ZimMultiReader.shared.getMainPageURL(zimFileID: zimFile.id) else { return }
        load(url: mainPageURL)
    }
    
    func houseButtonTapped() {
        withAnimation(Animation.easeInOut(duration: 0.2)) {
            contentDisplayMode = contentDisplayMode == .homeView ? .webView : .homeView
        }
    }
    
    func scrollToOutlineItem(index: Int) {
        webView.evaluateJavaScript("outlines.scrollToView(\(index))")
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
            currentExternalURL = url
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
        if contentDisplayMode == .transitionView {
            withAnimation(.easeOut(duration: 0.1)) { contentDisplayMode = .webView }
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
