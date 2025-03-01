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
            try? context.save()

            if url.lastPathComponent.hasSuffix(".meta4") {
                url = url.deletingPathExtension()
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.allowsCellularAccess = allowsCellularAccess
            let task = self.session.downloadTask(with: urlRequest)
            task.countOfBytesClientExpectsToReceive = zimFile.size
            task.taskDescription = zimFileID.uuidString
            task.resume()
        }
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
            try? context.save()
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
                try context.save()
            } catch {
                os_log(
                    "Error deleting download task. Error: %s",
                    log: Log.DownloadService,
                    type: .error,
                    error.localizedDescription
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
        guard let taskDescription = task.taskDescription,
              let zimFileID = UUID(uuidString: taskDescription),
              let httpResponse = task.response as? HTTPURLResponse else { return }
        // download finished successfully if there's no error
        // and the status code is in the 200 < 300 range
        guard let error = error as NSError? else {
            if (200..<300).contains(httpResponse.statusCode) {
                os_log(
                    "Download finished successfully. File ID: %s.",
                    log: Log.DownloadService,
                    type: .info,
                    zimFileID.uuidString
                )
            } else {
                os_log(
                    "Download was unsuccessful. File ID: %s. status code: %i",
                    log: Log.DownloadService,
                    type: .info,
                    zimFileID.uuidString,
                    httpResponse.statusCode
                )
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
                try? context.save()
            }
        }
        os_log(
            "Download finished for File ID: %s. with: %s",
            log: Log.DownloadService,
            type: .error,
            zimFileID.uuidString,
            error.localizedDescription
        )
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

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let httpResponse = downloadTask.response as? HTTPURLResponse else { return }

        guard (200..<300).contains(httpResponse.statusCode) else {
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: .alert,
                    object: nil,
                    userInfo: ["rawValue": ActiveAlert.downloadFailed.rawValue]
                )
            }
            return
        }

        // determine which directory should the file be moved to
        #if os(macOS)
        let searchPath = FileManager.SearchPathDirectory.downloadsDirectory
        #elseif os(iOS)
        let searchPath = FileManager.SearchPathDirectory.documentDirectory
        #endif

        // move file
        guard let directory = FileManager.default.urls(for: searchPath, in: .userDomainMask).first,
            let zimFileID = UUID(uuidString: downloadTask.taskDescription ?? "") else { return }
        let fileName = downloadTask.response?.suggestedFilename
            ?? downloadTask.originalRequest?.url?.lastPathComponent
            ?? zimFileID.uuidString + ".zim"
        let destination = directory.appendingPathComponent(fileName)
        try? FileManager.default.moveItem(at: location, to: destination)

        // open the file
        Task { @ZimActor in
            await LibraryOperations.open(url: destination)
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
