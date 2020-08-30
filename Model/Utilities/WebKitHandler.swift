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
    let activeRequestsSemaphore = DispatchSemaphore(value: 1)
    let dataFetchingSemaphore = DispatchSemaphore(value: ProcessInfo.processInfo.activeProcessorCount)
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        // unpack zimFileID and content path from the url
        guard let url = urlSchemeTask.request.url,
            url.isKiwixURL,
            let contentPath = url.path.removingPercentEncoding,
            let zimFileID = url.host else {
                urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
                return
        }
        
        // remember this active url scheme task
        activeRequestsSemaphore.wait()
        activeRequests.insert(urlSchemeTask.request)
        activeRequestsSemaphore.signal()
        
        // fetch data and send response on another thread
        DispatchQueue.global(qos: .userInitiated).async {
            // fetch data
            self.dataFetchingSemaphore.wait()
            let content = ZimMultiReader.shared.getContent(bookID: zimFileID, contentPath: contentPath)
            self.dataFetchingSemaphore.signal()
            
            // check the url scheme task is not stopped
            self.activeRequestsSemaphore.wait()
            guard let _ = self.activeRequests.remove(urlSchemeTask.request) else { self.activeRequestsSemaphore.signal(); return }
            self.activeRequestsSemaphore.signal()
            
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
        activeRequestsSemaphore.wait()
        activeRequests.remove(urlSchemeTask.request)
        activeRequestsSemaphore.signal()
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
