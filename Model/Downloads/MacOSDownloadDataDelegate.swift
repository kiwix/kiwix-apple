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
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        willCacheResponse proposedResponse: CachedURLResponse
    ) async -> CachedURLResponse? {
        // we don't want any caching here
        .none
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        guard let zimFileID = dataTask.zimFileID else {
            Log.DownloadService.error("cannot handle dataTask received response: \(dataTask, )")
            return .cancel
        }
        Task { @MainActor [weak progress] in
            progress?.updateFor(
                uuid: zimFileID,
                downloaded: dataTask.countOfBytesReceived,
                total: response.expectedContentLength
            )
        }
        Log.DownloadService.debug("didReceive dataTask response: \(response)")
        return .allow
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let zimFileID = dataTask.zimFileID else {
            Log.DownloadService.error("cannot handle dataTaks received data: \(dataTask)")
            return
        }
        Log.DownloadService.debug("didReceive dataTask data: \(dataTask) \(data.count)")
        Task { @MainActor [weak progress] in
            progress?
                .updateFor(
                    uuid: zimFileID,
                    downloaded: dataTask.countOfBytesReceived,
                    total: dataTask.response?.expectedContentLength ?? dataTask.countOfBytesExpectedToReceive
                )
        }
    }
    
    // TODO: remove
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didBecome downloadTask: URLSessionDownloadTask
    ) {
        Log.DownloadService.debug("didBecome downloadTask: \(downloadTask)")
    }
    
    // TODO: remove
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        Log.DownloadService.debug("didBecome streamTask: \(streamTask)")
    }
}
