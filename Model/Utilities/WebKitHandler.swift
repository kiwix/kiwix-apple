/*
 * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

import os
import WebKit

/// Skipping handling for HTTP 206 Partial Content
/// For video playback, WebKit makes a large amount of requests with small byte range (e.g. 8 bytes)
/// to retrieve content of the video.
/// As a result of the large volume of small requests, CPU usage will be very high,
/// which can result in app or webpage frozen.
/// To mitigate, opting for the less "broken" behavior of ignoring Range header
/// until WebKit behavior is changed.
final class KiwixURLSchemeHandler: NSObject, WKURLSchemeHandler {
    static let KiwixScheme = "kiwix"
    private let queue = DispatchQueue.main
    private let inSync = InSync(label: "org.kiwix.url.scheme.sync")
    private var startedTasks: [Int: Bool] = [:]

    private func startFor(_ hash: Int) {
        inSync.execute {
            self.startedTasks[hash] = true
        }
    }

    private func isStartedFor(_ hash: Int) -> Bool {
        return inSync.read {
            self.startedTasks[hash] != nil
        }
    }

    private func stopFor(_ hash: Int) {
        inSync.execute {
            self.startedTasks.removeValue(forKey: hash)
        }
    }

    private func stopAll() {
        inSync.execute {
            self.startedTasks.removeAll()
        }
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let hash = urlSchemeTask.hash
        guard isStartedFor(hash) == false else { return }
        startFor(hash)

        queue.async { [weak self] in
            guard let url = urlSchemeTask.request.url, url.isKiwixURL else {
                urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
                self?.stopFor(hash)
                return
            }
            guard let content = ZimFileService.shared.getURLContent(url: url) else {
                self?.sendHTTP404Response(urlSchemeTask, url: url)
                self?.stopFor(hash)
                return
            }
            self?.sendHTTP200Response(urlSchemeTask, url: url, content: content)
            self?.stopFor(hash)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        stopFor(urlSchemeTask.hash)
    }

    func didFailProvisionalNavigation() {
        stopAll()
    }

    private func sendHTTP200Response(_ urlSchemeTask: WKURLSchemeTask, url: URL, content: URLContent) {
        let headers = ["Content-Type": content.httpContentType, "Content-Length": "\(content.size)"]
        if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) {
            guard isStartedFor(urlSchemeTask.hash) else { return }
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(content.data)
            urlSchemeTask.didFinish()
        } else {
            guard isStartedFor(urlSchemeTask.hash) else { return }
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
    }

    private func sendHTTP404Response(_ urlSchemeTask: WKURLSchemeTask, url: URL) {
        if let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil) {
            guard isStartedFor(urlSchemeTask.hash) else { return }
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didFinish()
        } else {
            guard isStartedFor(urlSchemeTask.hash) else { return }
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
    }
}
