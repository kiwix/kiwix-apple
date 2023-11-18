//
//  BrowserNavHandler.swift
//  Kiwix
//
//  Copyright © 2023 Chris Li. All rights reserved.
//

import CoreLocation
import WebKit

final class BrowserNavDelegate: NSObject, WKNavigationDelegate {
    @Published private(set) var externalURL: URL?

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isKiwixURL, let redirectedURL = ZimFileService.shared.getRedirectedURL(url: url) {
            if webView.url != redirectedURL {
                DispatchQueue.main.async { webView.load(URLRequest(url: redirectedURL)) }
            }
            decisionHandler(.cancel)
        } else if url.isKiwixURL {
            decisionHandler(.allow)
        } else if url.isExternal {
            externalURL = url
            decisionHandler(.cancel)
        } else if url.scheme == "geo" {
            if FeatureFlags.map {
                let _: CLLocation? = {
                    let parts = url.absoluteString.replacingOccurrences(of: "geo:", with: "").split(separator: ",")
                    guard let latitudeString = parts.first,
                          let longitudeString = parts.last,
                          let latitude = Double(latitudeString),
                          let longitude = Double(longitudeString) else { return nil }
                    return CLLocation(latitude: latitude, longitude: longitude)
                }()
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

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItems();")
        #if os(iOS)
            webView.adjustTextSize()
        #endif
    }

    func webView(
        _: WKWebView,
        didFailProvisionalNavigation _: WKNavigation!,
        withError error: Error
    ) {
        let error = error as NSError
        guard error.code != NSURLErrorCancelled else { return }
        NotificationCenter.default.post(
            name: .alert, object: nil, userInfo: ["rawValue": ActiveAlert.articleFailedToLoad.rawValue]
        )
    }
}
