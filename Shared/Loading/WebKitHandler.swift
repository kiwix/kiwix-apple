//
//  KiwixURLSchemeHandler.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import WebKit

@available(iOS 11.0, *)
class KiwixURLSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
            url.isKiwixURL,
            let contentPath = url.path.removingPercentEncoding,
            let id = url.host else {
                urlSchemeTask.didFailWithError(ResourceLoadingError.invalidURL)
                return
        }
        
        guard let content = ZimMultiReader.shared.getContent(bookID: id, contentPath: contentPath) else {
            urlSchemeTask.didFailWithError(ResourceLoadingError.contentNotFound)
            print("Webkit loading failed (404) for url (\(url.absoluteString)")
            return
        }
        
        let response = URLResponse(url: url, mimeType: content.mime, expectedContentLength: content.length, textEncodingName: nil)
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(content.data)
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

enum ResourceLoadingError: Error {
    case invalidURL
    case contentNotFound
}
