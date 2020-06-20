//
//  KiwixURLSchemeHandler.swift
//  Kiwix
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import os
import WebKit

class KiwixURLSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        // unpack zimFileID and content path from the url
        guard let url = urlSchemeTask.request.url,
            url.isKiwixURL,
            let contentPath = url.path.removingPercentEncoding,
            let zimFileID = url.host else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: nil)
                urlSchemeTask.didFailWithError(error)
                return
        }
        
        // assemble response
        if let content = ZimMultiReader.shared.getContent(bookID: zimFileID, contentPath: contentPath),
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": content.mime, "Content-Length": "\(content.length)"]
        ) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(content.data)
            urlSchemeTask.didFinish()
        } else {
            os_log("Resource not found for url: %s.", log: Log.URLSchemeHandler, type: .info, url.absoluteString)
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil)
            urlSchemeTask.didFailWithError(error)
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

extension URL {
    init?(zimFileID: String, contentPath: String) {
        let baseURLString = "kiwix://" + zimFileID
        guard let encoded = contentPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {return nil}
        self.init(string: encoded, relativeTo: URL(string: baseURLString))
    }

    var isKiwixURL: Bool {
        return scheme?.caseInsensitiveCompare("kiwix") == .orderedSame
    }
}
