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
                    defer { self.urls.remove(url) }
                    guard self.urls.contains(url) else { return }
                    guard let content = content else {
                        os_log(
                            "Resource not found for url: %s.",
                            log: Log.URLSchemeHandler,
                            type: .info,
                            url.absoluteString
                        )
                        self.sendHTTP404Response(urlSchemeTask, url: url)
                        return
                    }
                    objCTryBlock {
                        if let range = urlSchemeTask.request.allHTTPHeaderFields?["Range"] as? String {
                            self.sendHTTP206Response(urlSchemeTask, url: url, content: content, range: range)
                        } else {
                            self.sendHTTP200Response(urlSchemeTask, url: url, content: content)
                        }
                    }
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
    
    private func sendHTTP200Response(_ urlSchemeTask: WKURLSchemeTask, url: URL, content: URLContent) {
        let headers = ["Content-Type": content.mime, "Content-Length": "\(content.size)"]
        if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(content.data)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
    }
    
    private func sendHTTP206Response(_ urlSchemeTask: WKURLSchemeTask, url: URL, content: URLContent, range: String) {
        let parts = range.components(separatedBy: ["=", "-"])
        guard parts.count == 3, let start = Int(parts[1]), let end = Int(parts[2]) else {
            if let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: nil) {
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didFinish()
            } else {
                urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
            }
            return
        }
        
        let data = content.data.subdata(in: start..<end + 1)
        let headers = [
            "Content-Type": content.mime,
            "Content-Length": "\(content.size)",
            "Content-Range": "bytes \(start)-\(end)/\(content.totalSize)"
        ]
        if let response = HTTPURLResponse(url: url, statusCode: 206, httpVersion: "HTTP/1.1", headerFields: headers) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
    }
    
    private func sendHTTP404Response(_ urlSchemeTask: WKURLSchemeTask, url: URL) {
        if let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
    }
}
