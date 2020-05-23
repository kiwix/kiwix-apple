//
//  WebKitTabController.swift
//  WikiMed
//
//  Created by Chris Li on 9/11/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import SwiftyUserDefaults


class WebKitWebController: UIViewController, WKUIDelegate, WKNavigationDelegate, WebViewController {
    private let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: config)
    }()
    weak var delegate: WebViewControllerDelegate?
    
    override func loadView() {
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
    }
    
    var canGoBack: Bool {
        get {return webView.canGoBack}
    }
    
    var canGoForward: Bool {
        get {return webView.canGoForward}
    }
    
    var currentURL: URL? {
        get {return webView.url}
    }
    
    var currentTitle: String? {
        return webView.title
    }
    
    // MARK: - Configure
    
    private func configureWebView() {
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsLinkPreview = true
        webView.allowsBackForwardNavigationGestures = true
    }
    
    // MARK: - loading
    
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    
    func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // MARK: - Capabilities
    
    func extractSnippet(completion: @escaping ((String?) -> Void)) {
        let javascript = "snippet.parse()"
        webView.evaluateJavaScript(javascript) { (result, error) in
            completion(result as? String)
        }
    }
    
    func extractImageURLs(completion: @escaping (([URL]) -> Void)) {
        let javascript = "getImageURLs()"
        webView.evaluateJavaScript(javascript, completionHandler: { (results, error) in
            let urls = (results as? [String])?.compactMap({ URL(string: $0) }) ?? [URL]()
            completion(urls)
        })
    }
    
    func extractTableOfContents(completion: @escaping ((URL?, [TableOfContentItem]) -> Void)) {
        let javascript = "tableOfContents.getHeadingObjects()"
        webView.evaluateJavaScript(javascript, completionHandler: { (results, error) in
            let items = (results as? [[String: Any]])?.compactMap({ TableOfContentItem(rawValue: $0) }) ?? [TableOfContentItem]()
            completion(self.currentURL, items)
        })
    }
    
    func scrollToTableOfContentItem(index: Int) {
        let javascript = "tableOfContents.scrollToView(\(index))"
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    func adjustFontSize(scale: Double) {
        let javascript = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", scale * 100)
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isKiwixURL {
            guard let zimFileID = url.host else { decisionHandler(.cancel); return }
            if let redirectedPath = ZimMultiReader.shared.getRedirectedPath(zimFileID: zimFileID, contentPath: url.path),
                let redirectedURL = URL(bookID: zimFileID, contentPath: redirectedPath) {
                decisionHandler(.cancel)
                load(url: redirectedURL)
            } else {
                decisionHandler(.allow)
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            let policy = ExternalLinkLoadingPolicy(rawValue: Defaults.externalLinkLoadingPolicy) ?? .alwaysAsk
            if policy == .alwaysLoad {
                let controller = SFSafariViewController(url: url)
                self.present(controller, animated: true, completion: nil)
            } else {
                present(ExternalLinkAlertController(policy: policy, action: {
                    let controller = SFSafariViewController(url: url)
                    self.present(controller, animated: true, completion: nil)
                }), animated: true)
            }
            decisionHandler(.cancel)
        } else if url.scheme == "geo" {
            delegate?.webViewDidTapOnGeoLocation(controller: self, url: url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = Bundle.main.url(forResource: "Inject", withExtension: "js"),
            let javascript = try? String(contentsOf: url) {
            webView.evaluateJavaScript(javascript, completionHandler: { (_, error) in
                self.delegate?.webViewDidFinishLoading(controller: self)
            })
        } else {
            delegate?.webViewDidFinishLoading(controller: self)
        }
        if let scale = Defaults.webViewZoomScale, scale != 1 {
            adjustFontSize(scale: scale)
        }
    }
}


