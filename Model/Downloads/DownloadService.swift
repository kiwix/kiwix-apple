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

import Combine
import CoreData
import UserNotifications
import os

// swiftlint:disable:next type_body_length
final class DownloadService: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let shared = DownloadService()
    private let queue = DispatchQueue(label: "downloads", qos: .background)
    @MainActor let progress = DownloadTasksPublisher()
    @MainActor private var heartbeat: Timer?
    var backgroundCompletionHandler: (@MainActor () -> Void)?
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.background")
        configuration.allowsCellularAccess = true
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue
        return URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
    }()

    // MARK: - Heartbeat

    /// Restart heartbeat if there are unfinished download task
    func restartHeartbeatIfNeeded() {
        session.getTasksWithCompletionHandler { [weak self] _, _, downloadTasks in
            guard downloadTasks.count > 0 else { return }
            for task in downloadTasks {
                guard let taskDescription = task.taskDescription,
                      let zimFileID = UUID(uuidString: taskDescription) else { return }
                Task { @MainActor [weak self] in
                    self?.progress.updateFor(uuid: zimFileID, 
                                             downloaded: task.countOfBytesReceived,
                                             total: task.countOfBytesExpectedToReceive)
                }
            }
        }
    }

    // MARK: - Download Actions

    /// Start a zim file download task
    /// - Parameters:
    ///   - zimFile: the zim file to download
    ///   - allowsCellularAccess: if using cellular data is allowed
    @MainActor func start(zimFileID: UUID, allowsCellularAccess: Bool) {
        requestNotificationAuthorization()
        Database.shared.performBackgroundTask { [self] context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            let fetchRequest = ZimFile.fetchRequest(fileID: zimFileID)
            guard let zimFile = try? context.fetch(fetchRequest).first,
                  var url = zimFile.downloadURL else {
                return
            }
            let downloadTask = DownloadTask(context: context)
            downloadTask.created = Date()
            downloadTask.fileID = zimFileID
            downloadTask.zimFile = zimFile
            Task { @MainActor [weak context] in
                try? context?.save()
            }

            if url.lastPathComponent.hasSuffix(".meta4") {
                url = url.deletingPathExtension()
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.allowsCellularAccess = allowsCellularAccess
            let task = self.session.downloadTask(with: urlRequest)
            task.countOfBytesClientExpectsToReceive = zimFile.size
            task.taskDescription = zimFileID.uuidString
            
            guard let destination = DownloadDestination.filePathFor(downloadURL: url) else {
                showAlert(.downloadError(#line, LocalString.download_service_error_option_directory))
                task.cancel()
                deleteDownloadTask(zimFileID: zimFileID)
                return
            }
            
            guard !FileManager.default.fileExists(atPath: destination.path()) else {
                showQuestion(
                    ActiveQuestion(
                        text: questionText(destination: destination, zimFileName: zimFile.name),
                        yes: LocalString.common_button_yes,
                        cancel: LocalString.common_button_cancel,
                        didConfirm: {
                            task.resume()
                        },
                        didDismiss: { [weak self] in
                            task.cancel()
                            self?.deleteDownloadTask(zimFileID: zimFileID)
                        }
                    )
                )
                return
            }
            
            task.resume()
        }
    }
    
    private func questionText(destination: URL, zimFileName: String) -> String {
        [LocalString.download_again_question_title,
         LocalString.download_again_question_description_part_1(withArgs: destination.lastPathComponent),
         LocalString.download_again_question_description_part_2(withArgs: zimFileName)
        ].joined(separator: "\n\n")
    }

    /// Cancel a zim file download task
    /// - Parameter zimFileID: identifier of the zim file
    func cancel(zimFileID: UUID) {
        session.getTasksWithCompletionHandler { _, _, downloadTasks in
            if let task = downloadTasks.filter({ $0.taskDescription == zimFileID.uuidString }).first {
                task.cancel()
            }
            self.deleteDownloadTask(zimFileID: zimFileID)
        }
    }

    /// Pause a zim file download task
    /// - Parameter zimFileID: identifier of the zim file
    func pause(zimFileID: UUID) {
        session.getTasksWithCompletionHandler { [progress] _, _, downloadTasks in
            guard let task = downloadTasks.filter({ $0.taskDescription == zimFileID.uuidString }).first else { return }
            task.cancel { [progress] resumeData in
                Task { @MainActor [progress] in
                    progress.updateFor(uuid: zimFileID, withResumeData: resumeData)
                }
            }
        }
    }

    /// Resume a zim file download task and start heartbeat
    /// - Parameter zimFileID: identifier of the zim file
    @MainActor func resume(zimFileID: UUID) {
        requestNotificationAuthorization()

        guard let resumeData = progress.resumeDataFor(uuid: zimFileID) else { return }
        progress.updateFor(uuid: zimFileID, withResumeData: nil)

        Database.shared.performBackgroundTask { [self, resumeData] context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            let request = DownloadTask.fetchRequest(fileID: zimFileID)
            guard let downloadTask = try? context.fetch(request).first else { return }

            let task = self.session.downloadTask(withResumeData: resumeData)
            task.taskDescription = zimFileID.uuidString
            task.resume()

            downloadTask.error = nil
            Task { @MainActor [weak context] in
                try? context?.save()
            }
        }
    }

    // MARK: - Database

    private func deleteDownloadTask(zimFileID: UUID) {
        Task { @MainActor [weak progress] in
            progress?.resetFor(uuid: zimFileID)
        }
        Database.shared.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            do {
                let request = DownloadTask.fetchRequest(fileID: zimFileID)
                guard let downloadTask = try context.fetch(request).first else { return }
                context.delete(downloadTask)
                Task { @MainActor [weak context] in
                    try context?.save()
                }
            } catch {
                let fileId = zimFileID.uuidString
                let errorDesc = error.localizedDescription
                Log.DownloadService.error(
                    "Error deleting download task for: \(fileId, privacy: .public), \(errorDesc, privacy: .public)"
                )
            }
        }
    }

    // MARK: - Notification

    @MainActor private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleDownloadCompleteNotification(zimFileID: UUID) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus != .denied else { return }
            Database.shared.performBackgroundTask { context in
                // configure notification content
                let content = UNMutableNotificationContent()
                content.title = LocalString.download_service_complete_title
                content.sound = .default
                if let zimFile = try? context.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first {
                    content.body = LocalString.download_service_complete_description(withArgs: zimFile.name)
                }
                // schedule notification
                let request = UNNotificationRequest(identifier: zimFileID.uuidString, content: content, trigger: nil)
                center.add(request)
            }
        }
    }

    // MARK: - URLSessionTaskDelegate

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let taskDescription = task.taskDescription else {
            Log.DownloadService.fault("No taskDescription")
            return
        }
        guard let zimFileID = UUID(uuidString: taskDescription) else {
            Log.DownloadService.fault("Cannot convert taskDescription: \(taskDescription, privacy: .public)")
            return
        }
        guard let httpResponse = task.response as? HTTPURLResponse else {
            Log.DownloadService.fault("response is not an HTTPURLResponse")
            return
        }
        // download finished successfully if there's no error
        // and the status code is in the 200 < 300 range
        guard let error = error as NSError? else {
            let fileId = zimFileID.uuidString
            if (200..<300).contains(httpResponse.statusCode) {
                Log.DownloadService.info(
                    "Download Ok, zimId: \(fileId, privacy: .public)"
                )
            } else {
                let statusCode = httpResponse.statusCode
                Log.DownloadService.error(
                    "Download error: \(fileId, privacy: .public). status code: \(statusCode, privacy: .public)")
                self.deleteDownloadTask(zimFileID: zimFileID)
            }
            return
        }

       // Save the error description and resume data if there are new result data
        let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
        Task { @MainActor [progress] in
            // The result data equality check is used as a trick to distinguish user pausing 
            // the download task vs failure.
            // When pausing, the same resume data would have already been saved when the delegate is called.
            guard progress.resumeDataFor(uuid: zimFileID) != resumeData else {
                return
            }
            progress.updateFor(uuid: zimFileID, withResumeData: resumeData)

            Database.shared.performBackgroundTask { context in
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                let request = DownloadTask.fetchRequest(fileID: zimFileID)
                guard let downloadTask = try? context.fetch(request).first else { return }
                downloadTask.error = error.localizedDescription
                Task { @MainActor [weak context] in
                    try? context?.save()
                }
            }
        }
        let fileId = zimFileID.uuidString
        let errorDesc = error.localizedDescription
        Log.DownloadService.error(
            "Finished for zimId: \(fileId, privacy: .public). with: \(errorDesc, privacy: .public)")
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession,
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
    
    private func showAlert(_ alert: ActiveAlert) {
        Task { @MainActor in
            NotificationCenter.default.post(name: .alert,
                                            object: nil,
                                            userInfo: ["alert": alert])
        }
    }
    
    private func showQuestion(_ question: ActiveQuestion) {
        Task { @MainActor in
            NotificationCenter.default.post(name: .question, object: nil, userInfo: ["question": question])
        }
    }

    // swiftlint:disable:next function_body_length
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let httpResponse = downloadTask.response as? HTTPURLResponse else {
            Log.DownloadService.fault("Response is not an HTTPURLResponse")
            showAlert(.downloadError(#line, LocalString.download_service_error_option_invalid_response))
            return
        }
        let taskId = downloadTask.taskDescription ?? ""
        guard let zimFileID = UUID(uuidString: taskId) else {
            Log.DownloadService.fault(
                "Cannot convert downloadTask to zimFileID: \(taskId, privacy: .public)"
            )
            showAlert(.downloadError(#line, LocalString.download_service_error_option_invalid_taskid))
            return
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let taskId = downloadTask.taskIdentifier.description
            let statusCode = httpResponse.statusCode
            Log.DownloadService.error(
                "didFinish failed for: \(taskId, privacy: .public), status: \(statusCode, privacy: .public)")
            showAlert(.downloadFailed(zimFileID))
            deleteDownloadTask(zimFileID: zimFileID)
            return
        }
        guard let url = httpResponse.url,
           var destination = DownloadDestination.filePathFor(downloadURL: url) else {
            showAlert(.downloadError(#line, LocalString.download_service_error_option_directory))
            deleteDownloadTask(zimFileID: zimFileID)
            return
        }
        let fileName = destination.lastPathComponent
        
        Log.DownloadService.info(
            "Start moving zimFile: \(fileName, privacy: .public), \(zimFileID.uuidString, privacy: .public)"
        )
        do {
            var count = 0
            let maxAttempts = 3
            var nextDestination = destination
            while FileManager.default.fileExists(atPath: nextDestination.path()), count <= maxAttempts {
                nextDestination = DownloadDestination.alternateLocalPathFor(downloadURL: destination, count: count)
                count += 1
            }
            destination = nextDestination
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            Log.DownloadService.error("""
Unable to move file from: \(location.path(), privacy: .public) 
to: \(destination.absoluteString, privacy: .public), 
due to: \(error.localizedDescription, privacy: .public)
""")
            showAlert(.downloadError(#line, LocalString.download_service_error_option_unable_to_move_file))
            deleteDownloadTask(zimFileID: zimFileID)
        }
        Log.DownloadService.info(
            "Completed moving zimFile: \(zimFileID.uuidString, privacy: .public)"
        )
        
        // open the file
        Task { @ZimActor in
            Log.DownloadService.info(
                "start opening zimFile: \(zimFileID.uuidString, privacy: .public)"
            )
            await LibraryOperations.open(url: destination)
            Log.DownloadService.info(
                "opened downloaded zimFile: \(zimFileID.uuidString, privacy: .public)"
            )
            // schedule notification
            scheduleDownloadCompleteNotification(zimFileID: zimFileID)
            deleteDownloadTask(zimFileID: zimFileID)
        }
    }

    // MARK: - URLSessionDelegate

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task { @MainActor [weak self] in
            self?.backgroundCompletionHandler?()
        }
    }
}
