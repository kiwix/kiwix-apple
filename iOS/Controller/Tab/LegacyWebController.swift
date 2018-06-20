//
//  LegacyTabViewViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import SafariServices
import JavaScriptCore
import SwiftyUserDefaults


class LegacyWebController: UIViewController, UIWebViewDelegate, WebViewController {
    
    private let webView = UIWebView()
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
        get {return webView.request?.url}
    }
    
    var currentTitle: String? {
        get {return webView.stringByEvaluatingJavaScript(from: "document.title")}
    }
    
    // MARK: - Configure
    
    private func configureWebView() {
        webView.delegate = self
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.allowsLinkPreview = true
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
        webView.loadRequest(request)
    }
    
    // MARK: - Capabilities
    
    func extractSnippet(completion: @escaping ((String?) -> Void)) {
        let javascript = "snippet.parse()"
        let snippet = webView.stringByEvaluatingJavaScript(from: javascript)
        completion(snippet)
    }
    
    func extractImageURLs(completion: @escaping (([URL]) -> Void)) {
        let javascript = "getImageURLs()"
        guard let urls = webView.context.evaluateScript(javascript).toArray() as? [String] else {completion([]); return}
        completion(urls.compactMap({ URL(string: $0) }))
    }
    
    func extractTableOfContents(completion: @escaping ((URL?, [TableOfContentItem]) -> Void)) {
        let javascript = "tableOfContents.getHeadingObjects()"
        guard let elements = webView.context.evaluateScript(javascript).toArray() as? [[String: Any]] else {completion(currentURL, []); return}
        let items = elements.compactMap({ TableOfContentItem(rawValue: $0) })
        completion(currentURL, items)
    }
    
    func scrollToTableOfContentItem(index: Int) {
        let javascript = "tableOfContents.scrollToView(\(index))"
        webView.context.evaluateScript(javascript)
    }
    
    func adjustFontSize(scale: Double) {
        let javascript = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", scale * 100)
        webView.stringByEvaluatingJavaScript(from: javascript)
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {return false}
        if url.isKiwixURL {
            guard let zimFileID = url.host else { return false }
            if let redirectedPath = ZimMultiReader.shared.getRedirectedPath(zimFileID: zimFileID, contentPath: url.path),
                let redirectedURL = URL(bookID: zimFileID, contentPath: redirectedPath) {
                DispatchQueue.main.async {
                    self.load(url: redirectedURL)
                }
                return false
            } else {
                return true
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            let policy = ExternalLinkLoadingPolicy(rawValue: Defaults[.externalLinkLoadingPolicy]) ?? .alwaysAsk
            if policy == .alwaysLoad {
                let controller = SFSafariViewController(url: url)
                self.present(controller, animated: true, completion: nil)
            } else {
                present(ExternalLinkAlertController(policy: policy, action: {
                    let controller = SFSafariViewController(url: url)
                    self.present(controller, animated: true, completion: nil)
                }), animated: true)
            }
            return false
        } else if url.scheme == "geo" {
            delegate?.webViewDidTapOnGeoLocation(controller: self, url: url)
            return false
        } else {
            return false
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if let url = Bundle.main.url(forResource: "Inject", withExtension: "js"),
            let javascript = try? String(contentsOf: url) {
            webView.stringByEvaluatingJavaScript(from: javascript)
        }
        delegate?.webViewDidFinishLoading(controller: self)
    }
}

fileprivate extension UIWebView {
    var context: JSContext {
        return value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
    }
}
