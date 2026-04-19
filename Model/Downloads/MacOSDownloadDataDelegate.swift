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

#if os(macOS)
import Foundation

final class MacOSDownloadDataDelegate: NSObject, URLSessionDataDelegate {
    private let progress: DownloadTasksPublisher
    private let downloadManager: DownloadTaskManager
    @IOActor
    private var writers: [UUID: DirectFileWriter] = [:]
    
    init(progress: DownloadTasksPublisher, downloadManager: DownloadTaskManager) {
        self.progress = progress
        self.downloadManager = downloadManager
    }
    
    // MARK: Init download
    
    /// This delegate method is called first
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive _: URLResponse // taking it from dataTask.response
    ) async -> URLSession.ResponseDisposition {
        guard let zimFileID = dataTask.zimFileID else {
            Log.DownloadService.error("cannot handle dataTask received response: \(dataTask)")
            DownloadUI
                .showAlert(.downloadErrorGeneric(description: LocalString.download_service_error_option_invalid_taskid))
            return .cancel
        }
        
        guard let progressData = Self.progressDataFrom(dataTask: dataTask),
            await setUpWriterFor(zimFileID: zimFileID, progress: progressData) else {
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
            DownloadUI
                .showAlert(
                    .downloadErrorZIM(
                        zimFileID: zimFileID,
                        errorMessage: LocalString.download_service_error_option_directory
                    )
                )
            return .cancel
        }
        
        await progress.updateFor(uuid: zimFileID, downloaded: progressData.downloaded, total: progressData.total)
        Log.DownloadService.debug("didReceive dataTask response: \(progressData.downloaded) | \(progressData.total)")
        return .allow
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    willCacheResponse _: CachedURLResponse) async -> CachedURLResponse? {
        // we don't want any caching
        .none
    }
    
    // MARK: Data progress
    // swiftlint:disable:next function_body_length
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let zimFileID = dataTask.zimFileID,
              let progressData = Self.progressDataFrom(dataTask: dataTask) else {
            Log.DownloadService.warning("didReceive dataTask data, but skipping progress for: \(dataTask)")
            return
        }
        Task { [weak progress, downloadManager, weak self] in
            guard let writer = await self?.writerFor(zimFileID: zimFileID) else {
                Log.DownloadService.error("there's no file writer for: \(zimFileID)")
                return
            }
            
            switch await writer.append(data: data) {
            case .appended:
                break // all good
            case .full:
                dataTask.suspend()
                if await writer.writeToDisk() {
                    dataTask.resume()
                } else {
                    dataTask.cancel()
                    try? FileManager.default.removeItem(at: writer.file)
                    downloadManager.deleteDownloadTask(zimFileID: zimFileID)
                    DownloadUI.showAlert(.downloadErrorZIM(
                        zimFileID: zimFileID,
                        errorMessage: LocalString.download_service_error_client_datanotallowed))
                    return
                }
            }
            await progress?.updateFor(uuid: zimFileID,
                                      downloaded: progressData.downloaded,
                                      total: progressData.total)
        
            // Download completed
            if progressData.isComplete() {
                guard await writer.writeToDisk() else {
                    DownloadUI.showAlert(.downloadErrorZIM(
                        zimFileID: zimFileID,
                        errorMessage: LocalString.download_service_error_client_datanotallowed))
                    downloadManager.deleteDownloadTask(zimFileID: zimFileID)
                    return
                }
                Log.DownloadService.debug(
                    "didReceive data completed: \(progressData.downloaded) | \(progressData.total) | for: \(zimFileID)"
                )
                
                // rename the file:
                if let originalURL = dataTask.originalRequest?.url,
                   let finalLocalFile = DownloadDestination.filePathWithFallbacksFor(downloadURL: originalURL) {
                    do {
                        try FileManager.default.moveItem(atPath: writer.file.path(),
                                                         toPath: finalLocalFile.path())
                        // open up the downloaded file
                        await LibraryOperations.open(url: finalLocalFile)
                        await DownloadCommonDelegate.scheduleDownloadCompleteNotification(zimFileID: zimFileID)
                        downloadManager.deleteDownloadTask(zimFileID: zimFileID)
                    } catch {
                        Log.DownloadService.error("""
Unable to rename file from: \(writer.file.path(), privacy: .public) 
to: \(finalLocalFile.path(), privacy: .public), 
due to: \(error.localizedDescription, privacy: .public)
""")
                        downloadManager.deleteDownloadTask(zimFileID: zimFileID)
                    }
                }
            } else {
                Log.DownloadService
                    .debug(
                        "didReceive data: \(progressData.downloaded) | \(progressData.total) | \(zimFileID.uuidString)"
                    )
            }
        }
    }
    // MARK: pause
    func pause(zimFileID: UUID, task: URLSessionDataTask) async {
        guard let progressData = Self.progressDataFrom(dataTask: task),
              let writer = await writerFor(zimFileID: zimFileID),
              let fileSize = await writer.fileSize() else {
            return
        }
        await progress.updateFor(uuid: zimFileID, downloaded: fileSize, total: progressData.total)
        let resumePointData = fileSize.description.data(using: .utf8)
        await progress.updateFor(uuid: zimFileID, withResumeData: resumePointData)
    }
        
    // MARK: cancel
    func cancel(zimFileID: UUID) {
        // just need the file part of it
        if let downloadFile = DirectDownloadInfo(initialOffset: 0, zimFileID: zimFileID)?.file {
            Log.DownloadService.debug("removing cancelled download file @ \(downloadFile.path())")
            try? FileManager.default.removeItem(at: downloadFile)
        }
        // downloadManager.deleteDownloadTask is already called
    }
    
    // MARK: complete
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        DownloadCommonDelegate.handleCompleteWithError(
            downloadManager: downloadManager,
            progress: progress,
            session: session,
            task: task,
            didCompleteWithError: error
        )
    }
    
    // MARK: helpers
    
    @IOActor
    private func setUpWriterFor(zimFileID: UUID, progress: ProgressData) async -> Bool {
        if let downloadInfo = DirectDownloadInfo(initialOffset: progress.downloaded, zimFileID: zimFileID),
                  let writer = DirectFileWriter(directAccess: downloadInfo) {
            writers[zimFileID] = writer
            return true
        }
        return false
    }
    
    @IOActor
    private func writerFor(zimFileID: UUID) async -> DirectFileWriter? {
        writers[zimFileID]
    }
    
    private static func progressDataFrom(dataTask: URLSessionDataTask) -> ProgressData? {
        guard let response = dataTask.response else {
            return nil
        }
        if let range = rangeFrom(response: response) {
            return ProgressData(downloaded: range.start + UInt(dataTask.countOfBytesReceived),
                                total: range.total)
        } else {
            return ProgressData(downloaded: UInt(dataTask.countOfBytesReceived),
                                total: UInt(dataTask.countOfBytesExpectedToReceive))
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
            if let start = UInt(match.1),
               let end = UInt(match.2),
               let total = UInt(match.3),
               0 <= start, start <= end, end <= total {
                return ResponseRange(start: start, end: end, total: total)
            } else {
                return nil
            }
        }
        return nil
    }
    
    private struct ProgressData {
        let downloaded: UInt
        let total: UInt
        
        func isComplete() -> Bool {
            downloaded == total
        }
    }
    
    private struct ResponseRange {
        let start: UInt
        let end: UInt
        let total: UInt
    }
}
#endif
