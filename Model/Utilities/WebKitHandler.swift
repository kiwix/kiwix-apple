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
    private var urls = Set<URL>()
    private var queue = DispatchQueue(label: "org.kiwix.webContent", qos: .userInitiated)
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        queue.async {
            // unpack zimFileID and content path from the url
            guard let url = urlSchemeTask.request.url, url.isKiwixURL else {
                urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
                return
            }
            
            // fetch url content and return data to the task
            self.urls.insert(url)
            DispatchQueue.global(qos: .userInitiated).async {
                let content = ZimFileService.shared.getURLContent(url: url)
                self.queue.async {
                    guard self.urls.contains(url) else { return }
                    if let content = content,
                       let response = HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: "HTTP/1.1",
                        headerFields: ["Content-Type": content.mime, "Content-Length": "\(content.length)"])
                    {
                        objCTryBlock {
                            urlSchemeTask.didReceive(response)
                            urlSchemeTask.didReceive(content.data)
                            urlSchemeTask.didFinish()
                        }
                    } else {
                        os_log(
                            "Resource not found for url: %s.",
                            log: Log.URLSchemeHandler,
                            type: .info,
                            url.absoluteString
                        )
                        urlSchemeTask.didFailWithError(URLError(.resourceUnavailable, userInfo: ["url": url]))
                    }
                    self.urls.remove(url)
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        queue.async {
            guard let url = urlSchemeTask.request.url else { return }
            self.urls.remove(url)
        }
    }
}
