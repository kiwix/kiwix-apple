//
//  WebKitWebController.swift
//  Kiwix
//
//  Created by Chris Li on 9/11/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import Defaults

class WebKitWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    private let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: config)
    }()
    weak var delegate: WebViewControllerDelegate?
    private(set) var outlineItems = [OutlineItem]()
    
    convenience init(url: URL) {
        self.init()
        load(url: url)
    }
    
    override func loadView() {
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
    }
    
    var canGoBack: Bool {
        get { webView.canGoBack }
    }
    
    var canGoForward: Bool {
        get { webView.canGoForward }
    }
    
    var currentURL: URL? {
        get { webView.url }
    }
    
    var currentTitle: String? {
        if let title = webView.title, title.count > 0 {
            return title
        } else {
            return nil
        }
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
    
    func extractOutlineItems(completion: @escaping ((URL?, [OutlineItem]) -> Void)) {
        let javascript = "outlines.getHeadingObjects()"
        webView.evaluateJavaScript(javascript, completionHandler: { (results, error) in
            let items = (results as? [[String: Any]])?.compactMap({ OutlineItem(rawValue: $0) }) ?? [OutlineItem]()
            completion(self.currentURL, items)
        })
    }
    
    func scrollToOutlineItem(index: Int) {
        let javascript = "outlines.scrollToView(\(index))"
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    func adjustFontSize(scale: Double) {
        let javascript = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", scale * 100)
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    func getFirstVisibleOutlineItemIndex(completion: @escaping ((Int?) -> Void)) {
        let javascript = "outlines.getVisibleHeadingIndex()"
        webView.evaluateJavaScript(javascript, completionHandler: { (indexes, error) in
            completion((indexes as? [Int])?.first)
        })
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isKiwixURL {
            guard let zimFileID = url.host else { decisionHandler(.cancel); return }
            if let redirectedPath = ZimMultiReader.shared.getRedirectedPath(zimFileID: zimFileID, contentPath: url.path),
                let redirectedURL = URL(zimFileID: zimFileID, contentPath: redirectedPath) {
                decisionHandler(.cancel)
                load(url: redirectedURL)
            } else {
                decisionHandler(.allow)
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            let policy = Defaults[.externalLinkLoadingPolicy]
            if policy == .alwaysLoad {
                let controller = SFSafariViewController(url: url)
                self.present(controller, animated: true, completion: nil)
            } else {
                present(UIAlertController.externalLink(policy: policy, action: {
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
                let javascript = "outlines.getHeadingObjects()"
                webView.evaluateJavaScript(javascript, completionHandler: { (results, error) in
                    self.outlineItems = (results as? [[String: Any]])?.compactMap({ OutlineItem(rawValue: $0) }) ?? [OutlineItem]()
                    self.delegate?.webViewDidFinishNavigation(controller: self)
                })
            })
        } else {
            delegate?.webViewDidFinishNavigation(controller: self)
        }
        if let scale = Defaults[.webViewZoomScale], scale != 1 {
            adjustFontSize(scale: scale)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard let error = error as? URLError else { return }
        if error.code == .resourceUnavailable {
            present(UIAlertController.resourceUnavailable(), animated: true)
        }
        delegate?.webViewDidFinishNavigation(controller: self)
    }
    
//    @available(iOS 13.0, *)
//    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
//        guard let url = elementInfo.linkURL else { completionHandler(nil); return }
//        let configuration = UIContextMenuConfiguration(
//            identifier: nil,
//            previewProvider: { WebViewController(url: url) },
//            actionProvider: { actions in
//                let viewMenu = UIAction(title: "View", image: UIImage(systemName: "eye.fill"), identifier: UIAction.Identifier(rawValue: "view")) {_ in
//                    print("button clicked..")
//                }
//
//                return UIMenu(title: url.path, image: nil, identifier: nil, children: [viewMenu])
//        })
//        completionHandler(configuration)
//    }
}

protocol WebViewControllerDelegate: class {
    func webViewDidTapOnGeoLocation(controller: WebKitWebViewController, url: URL)
    func webViewDidFinishNavigation(controller: WebKitWebViewController)
}
