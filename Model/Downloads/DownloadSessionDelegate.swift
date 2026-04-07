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

import CoreData
import Foundation
import UserNotifications

@MainActor
final class DownloadSessionDelegate: NSObject, URLSessionDownloadDelegate {
    var backgroundCompletionHandler: (() -> Void)?
    let progress: DownloadTasksPublisher
    let downloadManager: DownloadTaskManager
    #if os(macOS)
    nonisolated(unsafe) let macStreamingRegistry = MacStreamingDownloadRegistry()
    #endif

    init(progress: DownloadTasksPublisher, downloadManager: DownloadTaskManager) {
        self.progress = progress
        self.downloadManager = downloadManager
    }

    // swiftlint:disable function_body_length
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let taskDescription = task.taskDescription else {
            Log.DownloadService.fault("No taskDescription")
            return
        }
        guard let zimFileID = UUID(uuidString: taskDescription) else {
            Log.DownloadService.fault("Cannot convert taskDescription: \(taskDescription, privacy: .public)")
            return
        }

        #if os(macOS)
        if let dataTask = task as? URLSessionDataTask, !(task is URLSessionDownloadTask) {
            handleMacStreamingCompletion(dataTask: dataTask, zimFileID: zimFileID, error: error as NSError?)
            return
        }
        #endif

        guard let error = error as NSError? else {
            guard let httpResponse = task.response as? HTTPURLResponse else {
                Log.DownloadService.fault("response is not an HTTPURLResponse")
                downloadManager.deleteDownloadTask(zimFileID: zimFileID)
                let errorMessage = LocalString.download_service_error_option_invalid_response
                DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID,
                                                       errorMessage: errorMessage))
                return
            }
            let fileId = zimFileID.uuidString
            if (200..<300).contains(httpResponse.statusCode) {
                Log.DownloadService.info(
                    "Download Ok, zimId: \(fileId, privacy: .public)"
                )
            } else {
                let statusCode = httpResponse.statusCode
                Log.DownloadService.error("""
                Download error: \(fileId, privacy: .public). \
                URL: \(httpResponse.url?.absoluteString ?? "unknown", privacy: .public). \
                Status code: \(statusCode, privacy: .public),
                Error: \(httpResponse.debugDescription, privacy: .public)
                """)
                downloadManager.deleteDownloadTask(zimFileID: zimFileID)
            }
            return
        }

        guard error.code != NSURLErrorCancelled else {
            return
        }

        let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
        Task { @MainActor [progress] in
            progress.updateFor(uuid: zimFileID, withResumeData: resumeData)

            await Database.shared.viewContext.perform {
                let request = DownloadTask.fetchRequest(fileID: zimFileID)
                request.fetchLimit = 1
                guard let downloadTask = try? request.execute().first else { return }
                downloadTask.error = error.localizedDescription
                let context = Database.shared.viewContext
                try? context.save()
            }
        }
        let fileId = zimFileID.uuidString
        let errorDebugDesc = error.debugDescription
        Log.DownloadService.error(
            "Finished for zimId: \(fileId, privacy: .public). with: \(errorDebugDesc, privacy: .public)")

        let errorDesc = DownloadErrors.localizedString(from: error)
        downloadManager.deleteDownloadTask(zimFileID: zimFileID)
        DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID,
                                               errorMessage: errorDesc))
    }
    // swiftlint:enable function_body_length

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
        let snapshot = DownloadTaskDestinationStore.destination(for: zimFileID)
        #if os(macOS)
        let folder = snapshot?.resolvedFolderURL() ?? DownloadDestination.downloadLocalFolder()
        #else
        let folder = snapshot?.folderURL ?? DownloadDestination.downloadLocalFolder()
        #endif

        guard let url = httpResponse.url,
              let folder,
              var destination = DownloadDestination.filePathFor(downloadURL: url, in: folder) else {
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
            try DownloadDestination.withFolderAccess(to: folder) {
                var count = 0
                let maxAttempts = 3
                var nextDestination = destination
                while FileManager.default.fileExists(atPath: nextDestination.path()), count <= maxAttempts {
                    nextDestination = DownloadDestination.alternateLocalPathFor(downloadURL: destination, count: count)
                    count += 1
                }
                destination = nextDestination
                try FileManager.default.moveItem(at: location, to: destination)
            }
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
            return
        }
        Log.DownloadService.info(
            "Completed moving zimFile: \(zimFileID.uuidString, privacy: .public)"
        )

        Task {
            Log.DownloadService.info(
                "start opening zimFile: \(zimFileID.uuidString, privacy: .public)"
            )
            await LibraryOperations.open(url: destination)
            Log.DownloadService.info(
                "opened downloaded zimFile: \(zimFileID.uuidString, privacy: .public)"
            )
            await scheduleDownloadCompleteNotification(zimFileID: zimFileID)
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
        }
    }

    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task { @MainActor [weak self] in
            self?.backgroundCompletionHandler?()
        }
    }
    // MARK: - Notification

    func scheduleDownloadCompleteNotification(zimFileID: UUID) async {
        let center = UserNotifications.UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus != .denied else { return }

        let zimFileName: String? = await Database.shared.viewContext.perform {
            let request = ZimFile.fetchRequest(fileID: zimFileID)
            request.fetchLimit = 1
            if let zimFile = try? request.execute().first {
                return zimFile.name
            } else {
                return nil
            }
        }

        let content = UNMutableNotificationContent()
        content.title = LocalString.download_service_complete_title
        content.sound = .default
        if let zimFileName {
            content.body = LocalString.download_service_complete_description(withArgs: zimFileName)
        }
        let request = UNNotificationRequest(identifier: zimFileID.uuidString,
                                            content: content,
                                            trigger: nil)
        try? await center.add(request)
    }
}
