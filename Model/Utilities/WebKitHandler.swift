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
    private var activeRequests = Set<URLRequest>()
    let semaphore = DispatchSemaphore(value: 1)
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        // unpack zimFileID and content path from the url
        guard let url = urlSchemeTask.request.url,
            url.isKiwixURL,
            let contentPath = url.path.removingPercentEncoding,
            let zimFileID = url.host else {
                urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
                return
        }
        
        assert(Thread.isMainThread)
        
        // remember this active url scheme task
        semaphore.wait()
        activeRequests.insert(urlSchemeTask.request)
        semaphore.signal()
        
        // fetch data and send response on another thread
        DispatchQueue.global(qos: .userInitiated).async {
            // fetch data
            let content = ZimMultiReader.shared.getContent(bookID: zimFileID, contentPath: contentPath)
            
            // check the url scheme task is not stopped
            self.semaphore.wait()
            guard let _ = self.activeRequests.remove(urlSchemeTask.request) else { self.semaphore.signal(); return }
            self.semaphore.signal()
            
            // assemble and send response
            if let content = content,
               let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": content.mime, "Content-Length": "\(content.length)"])
            {
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(content.data)
                urlSchemeTask.didFinish()
            } else {
                os_log("Resource not found for url: %s.", log: Log.URLSchemeHandler, type: .info, url.absoluteString)
                urlSchemeTask.didFailWithError(URLError(.resourceUnavailable, userInfo: ["url": url]))
            }
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        semaphore.wait()
        activeRequests.remove(urlSchemeTask.request)
        semaphore.signal()
    }
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
