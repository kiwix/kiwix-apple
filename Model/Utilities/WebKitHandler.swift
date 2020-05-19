//
//  KiwixURLSchemeHandler.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import WebKit

class KiwixURLSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
            url.isKiwixURL,
            let contentPath = url.path.removingPercentEncoding,
            let id = url.host else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: nil)
                urlSchemeTask.didFailWithError(error)
                return
        }
        
        guard let content = ZimMultiReader.shared.getContent(bookID: id, contentPath: contentPath),
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": content.mime, "Content-Length": "\(content.length)"]) else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil)
                print("Webkit loading failed (404) for url (\(url.absoluteString)")
                urlSchemeTask.didFailWithError(error)
                return
        }
        
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(content.data)
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

extension URL {
    init?(bookID: String, contentPath: String) {
        let baseURLString = "kiwix://" + bookID
        guard let encoded = contentPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {return nil}
        self.init(string: encoded, relativeTo: URL(string: baseURLString))
    }
    
    var isKiwixURL: Bool {
        return scheme?.caseInsensitiveCompare("kiwix") == .orderedSame
    }
}
