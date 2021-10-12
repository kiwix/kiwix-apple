//
//  PreviewViewController.swift
//  QuickLook
//
//  Created by Chris Li on 10/11/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import UIKit
import QuickLook
import WebKit

class PreviewViewController: UIViewController, QLPreviewingController, WKNavigationDelegate {
    private var preparePreviewCompletionHandler: ((Error?) -> Void)?
    private let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        return WKWebView(frame: .zero, configuration: config)
    }()
        
    override func loadView() {
        view = webView
        webView.navigationDelegate = self
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        ZimFileService.shared.open(url: url)
        if let metadata = ZimFileService.getMetaData(url: url),
           let url = ZimFileService.shared.getMainPageURL(zimFileID: metadata.identifier) {
            webView.load(URLRequest(url: url))
            preparePreviewCompletionHandler = handler
        } else {
            handler(PreviewError.invalidFile(fileName: url.lastPathComponent))
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel, preferences)
        } else {
            decisionHandler(.allow, preferences)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        preparePreviewCompletionHandler?(nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        preparePreviewCompletionHandler?(error)
    }
}

enum PreviewError: Error, LocalizedError {
    case invalidFile(fileName: String)
}
