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

#if os(iOS)

import CoreData
import Foundation

@MainActor
final class IOSDownloadSessionDelegate: NSObject, URLSessionDownloadDelegate {
    var backgroundCompletionHandler: (() -> Void)?
    private let progress: DownloadTasksPublisher
    private let downloadManager: DownloadTaskManager
    
    init(progress: DownloadTasksPublisher, downloadManager: DownloadTaskManager) {
        self.progress = progress
        self.downloadManager = downloadManager
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DownloadCommonDelegate.handleCompleteWithError(
            downloadManager: downloadManager,
            progress: progress,
            session: session,
            task: task,
            didCompleteWithError: error
        )
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    nonisolated func urlSession(_ session: URLSession,
                                downloadTask: URLSessionDownloadTask,
                                didWriteData bytesWritten: Int64,
                                totalBytesWritten: Int64,
                                totalBytesExpectedToWrite: Int64) {
        guard let taskDescription = downloadTask.taskDescription,
              let zimFileID = UUID(uuidString: taskDescription) else { return }
        Task { @MainActor [progress] in
            progress.updateFor(uuid: zimFileID,
                               downloaded: totalBytesWritten,
                               total: totalBytesExpectedToWrite)
        }
    }
    
    // swiftlint:disable:next function_body_length
    nonisolated func urlSession(_ session: URLSession,
                                downloadTask: URLSessionDownloadTask,
                                didFinishDownloadingTo location: URL) {
        let taskId = downloadTask.taskDescription ?? ""
        guard let zimFileID = UUID(uuidString: taskId) else {
            Log.DownloadService.fault(
                "Cannot convert downloadTask to zimFileID: \(taskId, privacy: .public)"
            )
            DownloadUI.showAlert(
                .downloadErrorGeneric(
                    description: LocalString.download_service_error_option_invalid_taskid
                )
            )
            return
        }
        guard let httpResponse = downloadTask.response as? HTTPURLResponse else {
            let errorMessage = LocalString.download_service_error_option_invalid_response
            let url = downloadTask.originalRequest?.url
            let urlString = url?.absoluteString ?? "uknown"
            Log.DownloadService.fault("""
Response completed, but it is not an HTTPURLResponse URL: \(urlString, privacy: .public)
""")
            DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID,
                                                   errorMessage: errorMessage))
            return
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = httpResponse.statusCode
            let url = httpResponse.url
            let urlString = url?.absoluteString ?? "unknown"
            Log.DownloadService.error("""
DidFinish failed for: \(zimFileID, privacy: .public), URL: \(urlString, privacy: .public).
Status code: \(statusCode, privacy: .public)
""")
            let errorMessage = LocalString.download_service_error_option_http_status(withArgs: "\(statusCode)")
            DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID,
                                                   errorMessage: errorMessage))
            
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
            return
        }
        guard let url = httpResponse.url,
              var destination = DownloadDestination.filePathWithFallbacksFor(downloadURL: url) else {
            let errorMessage = LocalString.download_service_error_option_directory
            DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID,
                                                   errorMessage: errorMessage))
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
            return
        }
        let fileName = destination.lastPathComponent
        
        Log.DownloadService.info(
            "Start moving zimFile: \(fileName, privacy: .public), \(zimFileID.uuidString, privacy: .public)"
        )
        do {
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            Log.DownloadService.error("""
Unable to move file from: \(location.path(), privacy: .public) 
to: \(destination.absoluteString, privacy: .public), 
due to: \(error.localizedDescription, privacy: .public)
""")
            let errorMessage = LocalString.download_service_error_option_unable_to_move_file
            DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID,
                                                   errorMessage: errorMessage))
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
        }
        Log.DownloadService.info(
            "Completed moving zimFile: \(zimFileID.uuidString, privacy: .public)"
        )
        
        // open the file
        Task {
            Log.DownloadService.info(
                "start opening zimFile: \(zimFileID.uuidString, privacy: .public)"
            )
            await LibraryOperations.open(url: destination)
            Log.DownloadService.info(
                "opened downloaded zimFile: \(zimFileID.uuidString, privacy: .public)"
            )
            // schedule notification
            await DownloadCommonDelegate.scheduleDownloadCompleteNotification(zimFileID: zimFileID)
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
        }
    }
    
    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task { @MainActor [weak self] in
            self?.backgroundCompletionHandler?()
        }
    }
}
#endif
