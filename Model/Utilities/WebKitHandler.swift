//
//  KiwixURLSchemeHandler.swift
//  Kiwix
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import os
import WebKit

/// Skipping handling for HTTP 206 Partial Content
/// For video playback, WebKit makes a large amount of requests with small byte range (e.g. 8 bytes) 
/// to retrieve content of the video.
/// As a result of the large volume of small requests, CPU usage will be very high,
/// which can result in app or webpage frozen.
/// To mitigate, opting for the less "broken" behavior of ignoring Range header 
/// until WebKit behavior is changed.
class KiwixURLSchemeHandler: NSObject, WKURLSchemeHandler {
    private var urls = Set<URL>()
    private var queue = DispatchQueue(label: "org.kiwix.webContent", qos: .userInitiated)
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = urlSchemeTask.request.url, url.isKiwixURL else {
                urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
                return
            }
            do {
                objCTryBlock {
                    guard let content = ZimFileService.shared.getURLContent(url: url) else {
                        self.sendHTTP404Response(urlSchemeTask, url: url)
                        return
                    }
                    self.sendHTTP200Response(urlSchemeTask, url: url, content: content)
                }
            } catch let error {
                debugPrint(error)
            }
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) { }
    
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
    
    private func sendHTTP206Response(_ urlSchemeTask: WKURLSchemeTask, url: URL, content: URLContent) {
        let headers = [
            "Content-Type": content.mime,
            "Content-Length": "\(content.data.count)",
            "Content-Range": "bytes \(content.start)-\(content.end)/\(content.size)"
        ]
        if let response = HTTPURLResponse(url: url, statusCode: 206, httpVersion: "HTTP/1.1", headerFields: headers) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(content.data)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
    }
    
    private func sendHTTP400Response(_ urlSchemeTask: WKURLSchemeTask, url: URL) {
        os_log(
            "Resource not found for url: %s.",
            log: Log.URLSchemeHandler,
            type: .info,
            url.absoluteString
        )
        if let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: nil) {
            urlSchemeTask.didReceive(response)
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
