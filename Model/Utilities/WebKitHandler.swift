// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

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
    private let inSync = InSync(label: "org.kiwix.url.scheme.sync")
    private var startedTasks: [Int: Bool] = [:]

    // MARK: Life cycle

    private func startFor(_ hashValue: Int) async {
        await withCheckedContinuation { continuation in
            inSync.execute {
                self.startedTasks[hashValue] = true
                continuation.resume()
            }
        }
    }

    private func isStartedFor(_ hashValue: Int) -> Bool {
        return inSync.read {
            self.startedTasks[hashValue] != nil
        }
    }

    private func stopFor(_ hashValue: Int) {
        inSync.execute {
            self.startedTasks.removeValue(forKey: hashValue)
        }
    }

    private func stopAll() {
        inSync.execute {
            self.startedTasks.removeAll()
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        stopFor(urlSchemeTask.hash)
    }

    func didFailProvisionalNavigation() {
        stopAll()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard isStartedFor(urlSchemeTask.hash) == false else { return }
        Task {
            await startFor(urlSchemeTask.hash)
            await handle(task: urlSchemeTask)
        }
    }

    @MainActor
    private func handle(task urlSchemeTask: WKURLSchemeTask) async {
        let request = urlSchemeTask.request
        guard let url = request.url, url.isKiwixURL else {
            urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
            stopFor(urlSchemeTask.hash)
            return
        }
        guard let content = await readContent(for: url) else {
            sendHTTP404Response(urlSchemeTask, url: url)
            return
        }
        sendHTTP200Response(urlSchemeTask, url: url, content: content)

    }

    // MARK: Reading content

    private func readContent(for url: URL, start: UInt = 0, end: UInt = 0) async -> URLContent? {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .utility) {
                let content = ZimFileService.shared.getURLContent(url: url, start: start, end: end)
                continuation.resume(returning: content)
            }
        }
    }

    // MARK: Success responses
    @MainActor
    private func sendHTTP200Response(_ urlSchemeTask: WKURLSchemeTask, url: URL, content: URLContent) {
        guard isStartedFor(urlSchemeTask.hash) else { return }
        let headers = ["Content-Type": content.httpContentType,
                       "Content-Length": "\(content.size)"]
        if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(content.data)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
        stopFor(urlSchemeTask.hash)
    }

    // MARK: Error responses

    @MainActor
    private func sendHTTP404Response(_ urlSchemeTask: WKURLSchemeTask, url: URL) {
        guard isStartedFor(urlSchemeTask.hash) else { return }
        if let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
        stopFor(urlSchemeTask.hash)
    }
}
