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

import Foundation

final class MacOSDownloadDataDelegate: NSObject, URLSessionDataDelegate {
    private let progress: DownloadTasksPublisher
    private let downloadManager: DownloadTaskManager
    
    init(progress: DownloadTasksPublisher, downloadManager: DownloadTaskManager) {
        self.progress = progress
        self.downloadManager = downloadManager
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        DownloadCommonDelegate.handleCompleteWithError(
            downloadManager: downloadManager,
            progress: progress,
            session: session,
            task: task,
            didCompleteWithError: error
        )
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceiveInformationalResponse response: HTTPURLResponse
    ) {
        Log.DownloadService.debug("didReceiveInformationalResponse: \(response)")
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive _: URLResponse // taking it from dataTask.response
    ) async -> URLSession.ResponseDisposition {
        guard let zimFileID = dataTask.zimFileID else {
            Log.DownloadService.error("cannot handle dataTask received response: \(dataTask)")
            return .cancel
        }
        guard let progressData = Self.progressDataFrom(dataTask: dataTask) else {
            Log.DownloadService.warning("didReceive dataTask response, but skipping progress for \(dataTask)")
            return .allow
        }
        Task { @MainActor [weak progress] in
            progress?.updateFor(
                uuid: zimFileID,
                downloaded: progressData.downloaded,
                total: progressData.total
            )
        }
        Log.DownloadService.debug("didReceive dataTask response: \(progressData.downloaded) | \(progressData.total)")
        return .allow
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let zimFileID = dataTask.zimFileID,
              let progressData = Self.progressDataFrom(dataTask: dataTask) else {
            Log.DownloadService.warning("didReceive dataTask data, but skipping progress for: \(dataTask)")
            return
        }
        Task { @MainActor [weak progress] in
            progress?
                .updateFor(
                    uuid: zimFileID,
                    downloaded: progressData.downloaded,
                    total: progressData.total
                )
            
            if progressData.isComplete() {
                Log.DownloadService.debug("didReceive data completed for: \(zimFileID)")
                // schedule notification
                await DownloadCommonDelegate.scheduleDownloadCompleteNotification(zimFileID: zimFileID)
                downloadManager.deleteDownloadTask(zimFileID: zimFileID)
            } else {
                Log.DownloadService.debug("didReceive data: \(progressData.downloaded) | \(progressData.total)")
            }
        }
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    willCacheResponse proposedResponse: CachedURLResponse) async -> CachedURLResponse? {
        // we don't want any caching here
        .none
    }
    
    private static func progressDataFrom(dataTask: URLSessionDataTask) -> ProgressData? {
        guard let response = dataTask.response else { return nil }
        if let range = rangeFrom(response: response) {
            return ProgressData(downloaded: range.start + dataTask.countOfBytesReceived,
                                total: range.total)
        } else {
            return ProgressData(downloaded: dataTask.countOfBytesReceived,
                                total: dataTask.countOfBytesExpectedToReceive)
        }
    }
    
    private static func rangeFrom(response: URLResponse) -> ResponseRange? {
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 206, // range response
              let rangeString = httpResponse.value(forHTTPHeaderField: "Content-Range") else {
            return nil
        }
        let regex = /bytes (\d+)-(\d+)\/(\d+)/
        if let match = rangeString.firstMatch(of: regex) {
            if let start = Int64(match.1),
               let end = Int64(match.2),
               let total = Int64(match.3),
               0 <= start, start <= end, end <= total {
                return ResponseRange(start: start, end: end, total: total)
            } else {
                return nil
            }
        }
        return nil
    }
    
    private struct ProgressData {
        let downloaded: Int64
        let total: Int64
        
        func isComplete() -> Bool {
            downloaded == total
        }
    }
    
    private struct ResponseRange {
        let start: Int64
        let end: Int64
        let total: Int64
    }
}
