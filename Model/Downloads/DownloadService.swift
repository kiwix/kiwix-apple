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

@MainActor
final class DownloadService {
    @MainActor static let shared = DownloadService()
    let networkState: NetworkState
    let progress: DownloadTasksPublisher
    let sessionDelegate: DownloadSessionDelegate
    let downloadManager: DownloadTaskManager
    private let queue: DispatchQueue
    private var heartbeat: Timer?

    private let session: URLSession

    #if os(macOS)
    /// Observer for direct-write download completion notifications
    private var directWriteCompletionObserver: NSObjectProtocol?
    #endif

    private init() {
        queue = DispatchQueue(label: "downloads", qos: .background)
        progress = DownloadTasksPublisher()
        downloadManager = DownloadTaskManager(progress: progress)
        sessionDelegate = DownloadSessionDelegate(
            progress: progress,
            downloadManager: downloadManager)

        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.background")
        configuration.allowsCellularAccess = true
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue
        self.session = URLSession(
            configuration: configuration,
            delegate: sessionDelegate,
            delegateQueue: operationQueue
        )
        self.networkState = NetworkState()

        #if os(macOS)
        setupDirectWriteObserver()
        if DownloadDestination.shouldUseDirectWrite {
            _ = DirectWriteDownloadService.shared
        }
        #endif
    }

    #if os(macOS)
    private func setupDirectWriteObserver() {
        directWriteCompletionObserver = NotificationCenter.default.addObserver(
            forName: .directWriteDownloadCompleted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let zimFileID = userInfo["zimFileID"] as? UUID,
                  let fileURL = userInfo["fileURL"] as? URL else {
                return
            }
            Task { @MainActor [weak self] in
                self?.handleDirectWriteCompletion(zimFileID: zimFileID, fileURL: fileURL)
            }
        }
    }

    /// Handles completion of a direct-write download
    private func handleDirectWriteCompletion(zimFileID: UUID, fileURL: URL) {
        Log.DownloadService.info(
            "Direct-write download completed for \(zimFileID.uuidString, privacy: .public)"
        )

        // Re-acquire security-scoped access if using custom directory
        var needsSecurityScope = false
        if let customDir = DownloadDestination.customDownloadDirectory() {
            needsSecurityScope = customDir.startAccessingSecurityScopedResource()
        }

        // Open the file using the existing infrastructure
        Task {
            Log.DownloadService.info(
                "Opening direct-write downloaded zimFile: \(zimFileID.uuidString, privacy: .public)"
            )
            await LibraryOperations.open(url: fileURL)
            Log.DownloadService.info(
                "Opened direct-write downloaded zimFile: \(zimFileID.uuidString, privacy: .public)"
            )

            // Release security-scoped access
            if needsSecurityScope {
                fileURL.deletingLastPathComponent().stopAccessingSecurityScopedResource()
            }

            // Schedule download complete notification
            await scheduleDirectWriteCompleteNotification(zimFileID: zimFileID)
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
        }
    }

    /// Schedule a notification for direct-write download completion
    private func scheduleDirectWriteCompleteNotification(zimFileID: UUID) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus != .denied else { return }

        let zimFileName: String? = await Database.shared.viewContext.perform {
            if let zimFile = try? ZimFile.fetchRequest(fileID: zimFileID).execute().first {
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
    #endif

    // MARK: - Heartbeat

    /// Restart heartbeat if there are unfinished download task
    func restartHeartbeatIfNeeded() {
        session.getTasksWithCompletionHandler { [weak progress] _, _, downloadTasks in
            guard downloadTasks.count > 0 else { return }
            for task in downloadTasks {
                guard let taskDescription = task.taskDescription,
                      let zimFileID = UUID(uuidString: taskDescription) else { return }
                Task { @MainActor [weak progress] in
                    progress?.updateFor(uuid: zimFileID,
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
    func start(zimFileID: UUID, allowsCellularAccess: Bool) async {
        requestNotificationAuthorization()

        #if os(macOS)
        if DownloadDestination.shouldUseDirectWrite {
            await startDirectWriteDownload(zimFileID: zimFileID, allowsCellularAccess: allowsCellularAccess)
            return
        }
        #endif

        let downloadStruct = await Database.shared.viewContext.perform { () -> DownloadZimStruct? in
            let fetchRequest = ZimFile.fetchRequest(fileID: zimFileID)
            guard let zimFile = try? fetchRequest.execute().first,
                  var url = zimFile.downloadURL else {
                return nil
            }
            let context = Database.shared.viewContext
            let downloadTask = DownloadTask(context: context)
            downloadTask.created = Date()
            downloadTask.fileID = zimFileID
            downloadTask.zimFile = zimFile
            try? context.save()

            if url.lastPathComponent.hasSuffix(".meta4") {
                url = url.deletingPathExtension()
            }
            return DownloadZimStruct(url: url, name: zimFile.name, size: zimFile.size)
        }
        guard let downloadStruct else { return }
        let url = downloadStruct.url
        var urlRequest = URLRequest(url: url)
        urlRequest.allowsCellularAccess = allowsCellularAccess
        let task = self.session.downloadTask(with: urlRequest)
        task.countOfBytesClientExpectsToReceive = downloadStruct.size
        task.taskDescription = zimFileID.uuidString

        guard let destination = DownloadDestination.filePathFor(downloadURL: url) else {
            let errorMessage = LocalString.download_service_error_option_directory
            DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID, errorMessage: errorMessage))
            task.cancel()
            await downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
            return
        }

        guard !FileManager.default.fileExists(atPath: destination.path()) else {
            DownloadUI.showQuestion(
                ActiveQuestion(
                    text: questionText(destination: destination, zimFileName: downloadStruct.name),
                    yes: LocalString.common_button_yes,
                    cancel: LocalString.common_button_cancel,
                    didConfirm: { [weak self] in
                        self?.resumeTask(task, zimFileID: zimFileID)
                    },
                    didDismiss: { [weak self] in
                        task.cancel()
                        self?.downloadManager.deleteDownloadTask(zimFileID: zimFileID)
                    }
                )
            )
            return
        }
        resumeTask(task, zimFileID: zimFileID)

    }

    #if os(macOS)
    /// Starts a direct-write download on macOS (writes directly to custom directory)
    private func startDirectWriteDownload(zimFileID: UUID, allowsCellularAccess: Bool) async {
        let downloadInfo = await Database.shared.viewContext.perform { () -> (url: URL, size: Int64)? in
            let fetchRequest = ZimFile.fetchRequest(fileID: zimFileID)
            guard let zimFile = try? fetchRequest.execute().first,
                  var url = zimFile.downloadURL else {
                return nil
            }
            let context = Database.shared.viewContext
            let downloadTask = DownloadTask(context: context)
            downloadTask.created = Date()
            downloadTask.fileID = zimFileID
            downloadTask.zimFile = zimFile
            try? context.save()

            if url.lastPathComponent.hasSuffix(".meta4") {
                url = url.deletingPathExtension()
            }
            return (url: url, size: zimFile.size)
        }
        guard let downloadInfo else { return }

        await DirectWriteDownloadService.shared.start(
            zimFileID: zimFileID,
            downloadURL: downloadInfo.url,
            expectedSize: UInt64(max(0, downloadInfo.size)),
            allowsCellularAccess: allowsCellularAccess
        )
    }
    #endif

    private func resumeTask(_ task: URLSessionDownloadTask, zimFileID: UUID) {
        progress.updateFor(uuid: zimFileID,
                           downloaded: 0,
                           total: task.countOfBytesClientExpectsToReceive)
        task.resume()
    }

    private func questionText(destination: URL, zimFileName: String) -> String {
        [LocalString.download_again_question_title,
         LocalString.download_again_question_description_part_1(withArgs: destination.lastPathComponent),
         LocalString.download_again_question_description_part_2(withArgs: zimFileName)
        ].joined(separator: "\n\n")
    }

    /// Cancel a zim file download task
    /// - Parameter zimFileID: identifier of the zim file
    func cancel(zimFileID: UUID) async {
        #if os(macOS)
        if DirectWriteDownloadService.shared.activeDownloads[zimFileID] != nil {
            DirectWriteDownloadService.shared.cancel(zimFileID: zimFileID)
            await downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
            return
        }
        #endif

        let (_, _, downloadTasks) = await session.tasks
        if let task = downloadTasks.filter({ $0.taskDescription == zimFileID.uuidString }).first {
            task.cancel()
        }
        await downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
    }

    /// Pause a zim file download task
    /// - Parameter zimFileID: identifier of the zim file
    func pause(zimFileID: UUID) {
        #if os(macOS)
        if DirectWriteDownloadService.shared.activeDownloads[zimFileID] != nil {
            DirectWriteDownloadService.shared.pause(zimFileID: zimFileID)
            return
        }
        #endif

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
    func resume(zimFileID: UUID) async {
        requestNotificationAuthorization()

        #if os(macOS)
        if DirectWriteDownloadService.shared.activeDownloads[zimFileID] != nil {
            await DirectWriteDownloadService.shared.resume(zimFileID: zimFileID)
            return
        }
        #endif

        guard let resumeData = progress.resumeDataFor(uuid: zimFileID) else { return }
        progress.updateFor(uuid: zimFileID, withResumeData: nil)

        await Database.shared.viewContext.perform { [resumeData] in
            let request = DownloadTask.fetchRequest(fileID: zimFileID)
            guard let downloadTask = try? request.execute().first else { return }

            let task = self.session.downloadTask(withResumeData: resumeData)
            task.taskDescription = zimFileID.uuidString
            task.resume()

            downloadTask.error = nil

            let context = Database.shared.viewContext
            try? context.save()
        }
    }

    func allowsCellularAccessFor(zimFileID: UUID) async -> Bool? {
        let (_, _, downloadTasks) = await session.tasks
        let task = downloadTasks.first(where: { $0.taskDescription == zimFileID.uuidString })
        return task?.originalRequest?.allowsCellularAccess
    }

    // MARK: - Notification

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

// swiftlint:enable file_length
