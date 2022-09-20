//
//  ViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 9/3/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import WebKit

import Defaults

class ViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var activeAlert: ActiveAlert?
    @Published var activeSheet: ActiveSheet?
    @Published var navigationItem: NavigationItem? = .reading
    
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
            let coordinate = url.absoluteString.replacingOccurrences(of: "geo:", with: "")
            if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate)") {
                #if os(macOS)
                NSWorkspace.shared.open(url)
                #elseif os(iOS)
                UIApplication.shared.open(url)
                #endif
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItems();")
        webView.applyTextSizeAdjustmant()
    }
}
