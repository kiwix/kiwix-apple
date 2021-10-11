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
    private let activeRequestsSemaphore = DispatchSemaphore(value: 1)
    private let dataFetchingSemaphore = DispatchSemaphore(value: ProcessInfo.processInfo.activeProcessorCount)
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        // unpack zimFileID and content path from the url
        guard let url = urlSchemeTask.request.url,
            url.isKiwixURL else {
                urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
                return
        }
        
        // remember this active url scheme task
        activeRequestsSemaphore.wait()
        activeRequests.insert(urlSchemeTask.request)
        activeRequestsSemaphore.signal()
        
        // fetch data and send response
        DispatchQueue.global(qos: .userInitiated).async {
            // fetch data
            self.dataFetchingSemaphore.wait()
            let content = ZimFileService.shared.getURLContent(url: url)
            self.dataFetchingSemaphore.signal()
            
            // check the url scheme task is not stopped
            self.activeRequestsSemaphore.wait()
            guard let _ = self.activeRequests.remove(urlSchemeTask.request) else {
                self.activeRequestsSemaphore.signal()
                return
            }
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
