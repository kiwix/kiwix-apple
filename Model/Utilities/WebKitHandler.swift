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
        var start: UInt = 0
        var end: UInt = 0
        var isVideo = false
        if let mimeType = ZimFileService.shared.getMimeType(url: url) {
            isVideo = mimeType.contains("video")
            if isVideo {
                if let range = request.allHTTPHeaderFields?["Range"] as? String {
                    let parts = range.components(separatedBy: ["=", "-"])
                    guard parts.count > 1, let rangeStart = UInt(parts[1]) else {
                        sendHTTP400Response(urlSchemeTask, url: url)
                        return
                    }
                    let rangeEnd = parts.count == 3 ? UInt(parts[2]) ?? 0 : 0
                    start = rangeStart
                    end = rangeEnd
                }
            }
        }
        guard let content = await readContent(for: url, start: start, end: end) else {
            sendHTTP404Response(urlSchemeTask, url: url)
            stopFor(urlSchemeTask.hash)
            return
        }
        if isVideo {
            sendHTTP206Response(urlSchemeTask, url: url, content: content, start: start, end: end)
        } else {
            sendHTTP200Response(urlSchemeTask, url: url, content: content)
        }
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
        var headers = defaultResponseHeaders(for: content)
        headers["Content-Length"] = "\(content.size)"

        if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(content.data)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
        stopFor(urlSchemeTask.hash)
    }

    @MainActor
    private func sendHTTP206Response(
        _ urlSchemeTask: WKURLSchemeTask,
        url: URL,
        content: URLContent,
        start: UInt,
        end: UInt
    ) {
        guard isStartedFor(urlSchemeTask.hash) else {
            return
        }
        var headers = defaultResponseHeaders(for: content)
        headers["Content-Length"] = "\(content.rangeSize)"
        headers["Content-Range"] = content.contentRange(from: start, requestedEnd: end)

        if let response = HTTPURLResponse(url: url, statusCode: 206, httpVersion: "HTTP/1.1", headerFields: headers) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(content.data)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
        stopFor(urlSchemeTask.hash)
    }

    // MARK: Default headers sent back

    private func defaultResponseHeaders(for content: URLContent) -> [String: String] {
        var headers = [
            "Accept-Ranges": "bytes",
            "Content-Type": content.httpContentType,
            "Content-Length": "\(content.rangeSize)"
        ]
        if let modifiedDate = content.lastModified {
            headers["Last-Modified"] = modifiedDate.formatAsGMT()
        }
        if let eTag = content.eTag {
            headers["ETag"] = eTag
        }
        return headers
    }

    // MARK: Error responses

    @MainActor
    private func sendHTTP400Response(_ urlSchemeTask: WKURLSchemeTask, url: URL) {
        os_log(
            "Resource not found for url: %s.",
            log: Log.URLSchemeHandler,
            type: .info,
            url.absoluteString
        )
        guard isStartedFor(urlSchemeTask.hash) else { return }
        if let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: nil) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
        stopFor(urlSchemeTask.hash)
    }

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
