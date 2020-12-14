//
//  WebViewController.swift
//  Kiwix
//
//  Created by Chris Li on 12/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import Defaults

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: config)
    }()
    private var textSizeAdjustFactorObserver: NSKeyValueObservation?
    private var rootViewController: RootViewController? {
        splitViewController?.parent as? RootViewController
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }
    
    convenience init(url: URL) {
        self.init()
        webView.load(URLRequest(url: url))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14.0, *) {
            navigationController?.isNavigationBarHidden = true
        }
        
        // observe webView font size adjust factor
        textSizeAdjustFactorObserver = UserDefaults.standard.observe(\.webViewTextSizeAdjustFactor) { _, _ in
            self.adjustTextSize()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }
    
    func adjustTextSize() {
        let scale = UserDefaults.standard.webViewTextSizeAdjustFactor
        let javascript = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", scale * 100)
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    // MARK: - WKNavigationDelegate
    
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel, preferences); return }
        if url.isKiwixURL {
            guard let zimFileID = url.host else { decisionHandler(.cancel, preferences); return }
            if let redirectedPath = ZimMultiReader.shared.getRedirectedPath(zimFileID: zimFileID, contentPath: url.path),
                let redirectedURL = URL(zimFileID: zimFileID, contentPath: redirectedPath) {
                decisionHandler(.cancel, preferences)
                rootViewController?.openURL(redirectedURL)
            } else {
                preferences.preferredContentMode = .mobile
                decisionHandler(.allow, preferences)
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            let policy = Defaults[.externalLinkLoadingPolicy]
            if policy == .alwaysLoad {
                rootViewController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
            } else {
                rootViewController?.present(UIAlertController.externalLink(policy: policy, action: {
                    self.present(SFSafariViewController(url: url), animated: true, completion: nil)
                }), animated: true)
            }
            decisionHandler(.cancel, preferences)
        } else if url.scheme == "geo" {
            decisionHandler(.cancel, preferences)
        } else {
            decisionHandler(.cancel, preferences)
        }
    }
    
    // for iOS 12
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isKiwixURL {
            guard let zimFileID = url.host else { decisionHandler(.cancel); return }
            if let redirectedPath = ZimMultiReader.shared.getRedirectedPath(zimFileID: zimFileID, contentPath: url.path),
                let redirectedURL = URL(zimFileID: zimFileID, contentPath: redirectedPath) {
                decisionHandler(.cancel)
                rootViewController?.openURL(redirectedURL)
            } else {
                decisionHandler(.allow)
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            let policy = Defaults[.externalLinkLoadingPolicy]
            if policy == .alwaysLoad {
                rootViewController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
            } else {
                rootViewController?.present(UIAlertController.externalLink(policy: policy, action: {
                    self.present(SFSafariViewController(url: url), animated: true, completion: nil)
                }), animated: true)
            }
            decisionHandler(.cancel)
        } else if url.scheme == "geo" {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = Bundle.main.url(forResource: "Inject", withExtension: "js"), let javascript = try? String(contentsOf: url) {
            webView.evaluateJavaScript(javascript) { _, _ in
//                if #available(iOS 14.0, *), let outlineViewController = self.contentViewController.viewController(for: .primary) as? OutlineViewController {
//                    outlineViewController.reload()
//                } else if let outlineViewController = self.contentViewController.viewControllers.first as? OutlineViewController {
//                    outlineViewController.reload()
//                }
            }
        }
        adjustTextSize()
    }
    
    // MARK: - WKUIDelegate
    
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        guard let url = elementInfo.linkURL else { completionHandler(nil); return }
        if url.isKiwixURL {
            let config = UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: { WebViewController(url: url) },
                actionProvider: { elements -> UIMenu? in
                    UIMenu(children: elements)
                }
            )
            completionHandler(config)
        } else {
            completionHandler(nil)
        }
    }
}
