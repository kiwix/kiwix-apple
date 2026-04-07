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

    #if os(macOS)
    private let backgroundSession: URLSession
    private let directSession: URLSession
    #else
    private let session: URLSession
    #endif

    private struct DestinationPlan {
        let folder: URL
        let destination: URL
        let snapshot: DownloadTaskDestinationSnapshot
    }

    private init() {
        queue = DispatchQueue(label: "downloads", qos: .background)
        progress = DownloadTasksPublisher()
        downloadManager = DownloadTaskManager(progress: progress)
        sessionDelegate = DownloadSessionDelegate(
            progress: progress,
            downloadManager: downloadManager
        )

        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue

        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.background")
        backgroundConfiguration.allowsCellularAccess = true
        backgroundConfiguration.isDiscretionary = false
        backgroundConfiguration.sessionSendsLaunchEvents = true
        #if os(macOS)
        backgroundSession = URLSession(
            configuration: backgroundConfiguration,
            delegate: sessionDelegate,
            delegateQueue: operationQueue
        )

        let directConfiguration = URLSessionConfiguration.default
        directConfiguration.allowsCellularAccess = true
        directConfiguration.waitsForConnectivity = true
        directSession = URLSession(
            configuration: directConfiguration,
            delegate: sessionDelegate,
            delegateQueue: operationQueue
        )
        #else
        session = URLSession(
            configuration: backgroundConfiguration,
            delegate: sessionDelegate,
            delegateQueue: operationQueue
        )
        #endif

        networkState = NetworkState()
    }

    // MARK: - Heartbeat

    /// Restart heartbeat if there are unfinished download task
    func restartHeartbeatIfNeeded() {
        #if os(macOS)
        directSession.getTasksWithCompletionHandler { [weak progress] dataTasks, _, _ in
            if dataTasks.isEmpty {
                Task { @MainActor [weak self] in
                    self?.restoreMacStreamingProgress()
                }
                return
            }
            for task in dataTasks {
                guard let taskDescription = task.taskDescription,
                      let zimFileID = UUID(uuidString: taskDescription) else {
                    continue
                }
                Task { @MainActor [weak progress] in
                    progress?.updateFor(
                        uuid: zimFileID,
                        downloaded: task.countOfBytesReceived,
                        total: max(task.countOfBytesExpectedToReceive, task.countOfBytesReceived)
                    )
                }
            }
        }
        #else
        session.getTasksWithCompletionHandler { [weak progress] _, _, downloadTasks in
            guard downloadTasks.count > 0 else { return }
            for task in downloadTasks {
                guard let taskDescription = task.taskDescription,
                      let zimFileID = UUID(uuidString: taskDescription) else {
                    continue
                }
                Task { @MainActor [weak progress] in
                    progress?.updateFor(uuid: zimFileID,
                                        downloaded: task.countOfBytesReceived,
                                        total: task.countOfBytesExpectedToReceive)
                }
            }
        }
        #endif
    }

    #if os(macOS)
    private func restoreMacStreamingProgress() {
        for (zimFileID, metadata) in MacStreamingDownloadStore.all() {
            let downloaded = MacStreamingDownloadStore.partialFileSize(at: metadata.partialFileURL)
            progress.updateFor(
                uuid: zimFileID,
                downloaded: downloaded,
                total: max(metadata.expectedTotalBytes, downloaded)
            )
            progress.updateFor(uuid: zimFileID, withResumeData: metadata.resumeData(downloadedBytes: downloaded))
        }
    }
    #endif

    // MARK: - Download Actions

    /// Start a zim file download task
    /// - Parameters:
    ///   - zimFile: the zim file to download
    ///   - allowsCellularAccess: if using cellular data is allowed
    func start(zimFileID: UUID, allowsCellularAccess: Bool, destinationFolder: URL? = nil) async {
        requestNotificationAuthorization()
        guard let downloadStruct = await makeDownloadStruct(zimFileID: zimFileID) else {
            return
        }
        guard let plan = destinationPlan(for: downloadStruct.url, selectedFolder: destinationFolder) else {
            let errorMessage = LocalString.download_service_error_option_directory
            DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID, errorMessage: errorMessage))
            await downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
            return
        }

        guard !DownloadDestination.fileExists(at: plan.destination, in: plan.folder) else {
            DownloadUI.showQuestion(
                ActiveQuestion(
                    text: questionText(destination: plan.destination, zimFileName: downloadStruct.name),
                    yes: LocalString.common_button_yes,
                    cancel: LocalString.common_button_cancel,
                    didConfirm: { [weak self] in
                        Task { @MainActor in
                            await self?.startPreparedDownload(
                                zimFileID: zimFileID,
                                downloadStruct: downloadStruct,
                                allowsCellularAccess: allowsCellularAccess,
                                plan: plan
                            )
                        }
                    },
                    didDismiss: { [weak self] in
                        Task { @MainActor in
                            await self?.downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
                        }
                    }
                )
            )
            return
        }

        await startPreparedDownload(
            zimFileID: zimFileID,
            downloadStruct: downloadStruct,
            allowsCellularAccess: allowsCellularAccess,
            plan: plan
        )
    }

    private func makeDownloadStruct(zimFileID: UUID) async -> DownloadZimStruct? {
        await Database.shared.viewContext.perform { () -> DownloadZimStruct? in
            let fetchRequest = ZimFile.fetchRequest(fileID: zimFileID)
            fetchRequest.fetchLimit = 1
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
    }

    private func destinationPlan(for url: URL, selectedFolder: URL?) -> DestinationPlan? {
        guard let folder = DownloadDestination.downloadLocalFolder(selectedFolder: selectedFolder),
              let destination = DownloadDestination.filePathFor(downloadURL: url, in: folder) else {
            return nil
        }
        return DestinationPlan(
            folder: folder,
            destination: destination,
            snapshot: DownloadTaskDestinationSnapshot(folder: folder)
        )
    }

    private func startPreparedDownload(
        zimFileID: UUID,
        downloadStruct: DownloadZimStruct,
        allowsCellularAccess: Bool,
        plan: DestinationPlan
    ) async {
        #if os(macOS)
        do {
            try startMacStreamingDownload(
                zimFileID: zimFileID,
                downloadStruct: downloadStruct,
                allowsCellularAccess: allowsCellularAccess,
                plan: plan
            )
        } catch {
            let errorMessage = LocalString.download_service_error_option_directory
            DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID, errorMessage: errorMessage))
            await downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
        }
        #else
        var urlRequest = URLRequest(url: downloadStruct.url)
        urlRequest.allowsCellularAccess = allowsCellularAccess
        let task = session.downloadTask(with: urlRequest)
        task.countOfBytesClientExpectsToReceive = downloadStruct.size
        task.taskDescription = zimFileID.uuidString
        resumeTask(task, zimFileID: zimFileID, destinationSnapshot: plan.snapshot)
        #endif
    }

    #if os(macOS)
    private func startMacStreamingDownload(
        zimFileID: UUID,
        downloadStruct: DownloadZimStruct,
        allowsCellularAccess: Bool,
        plan: DestinationPlan
    ) throws {
        var request = URLRequest(url: downloadStruct.url)
        request.allowsCellularAccess = allowsCellularAccess

        let metadata = MacStreamingDownloadMetadata(
            sourceURL: downloadStruct.url,
            allowsCellularAccess: allowsCellularAccess,
            destinationSnapshot: plan.snapshot,
            destinationPath: plan.destination.path(),
            partialFilePath: DownloadDestination.partialFilePathFor(destination: plan.destination).path(),
            expectedTotalBytes: downloadStruct.size,
            entityTag: nil,
            lastModified: nil
        )
        let task = try makeMacStreamingTask(
            request: request,
            zimFileID: zimFileID,
            metadata: metadata,
            preservePartialFile: false
        )
        progress.updateFor(uuid: zimFileID, downloaded: 0, total: downloadStruct.size)
        progress.updateFor(uuid: zimFileID, withResumeData: nil)
        task.resume()
    }

    private func makeMacStreamingTask(
        request: URLRequest,
        zimFileID: UUID,
        metadata: MacStreamingDownloadMetadata,
        preservePartialFile: Bool
    ) throws -> URLSessionDataTask {
        let folder = metadata.destinationSnapshot.resolvedFolderURL()
        let destination = folder.appendingPathComponent(metadata.destinationURL.lastPathComponent)
        let partialFileURL = DownloadDestination.partialFilePathFor(destination: destination)
        let downloadedBytes = preservePartialFile ? MacStreamingDownloadStore.partialFileSize(at: partialFileURL) : 0

        let didAccess = folder.startAccessingSecurityScopedResource()
        do {
            if !preservePartialFile {
                try DownloadDestination.removeFileIfExists(at: partialFileURL, in: folder)
                guard FileManager.default.createFile(atPath: partialFileURL.path(), contents: nil) else {
                    throw MacStreamingDownloadError.invalidPartialFilePath
                }
            }

            let fileHandle = try FileHandle(forWritingTo: partialFileURL)
            if preservePartialFile {
                try fileHandle.seekToEnd()
            } else {
                try fileHandle.truncate(atOffset: 0)
                try fileHandle.seek(toOffset: 0)
            }

            let updatedMetadata = MacStreamingDownloadMetadata(
                sourceURL: metadata.sourceURL,
                allowsCellularAccess: metadata.allowsCellularAccess,
                destinationSnapshot: metadata.destinationSnapshot,
                destinationPath: destination.path(),
                partialFilePath: partialFileURL.path(),
                expectedTotalBytes: max(metadata.expectedTotalBytes, downloadedBytes),
                entityTag: metadata.entityTag,
                lastModified: metadata.lastModified
            )

            let task = directSession.dataTask(with: request)
            task.taskDescription = zimFileID.uuidString
            task.countOfBytesClientExpectsToReceive = updatedMetadata.expectedTotalBytes

            sessionDelegate.registerMacStreamingTask(
                taskID: task.taskIdentifier,
                zimFileID: zimFileID,
                sourceURL: updatedMetadata.sourceURL,
                allowsCellularAccess: updatedMetadata.allowsCellularAccess,
                folderURL: folder,
                didAccessSecurityScopedResource: didAccess,
                destinationSnapshot: updatedMetadata.destinationSnapshot,
                destinationURL: destination,
                partialFileURL: partialFileURL,
                expectedTotalBytes: updatedMetadata.expectedTotalBytes,
                downloadedBytes: downloadedBytes,
                fileHandle: fileHandle
            )

            DownloadTaskDestinationStore.save(updatedMetadata.destinationSnapshot, for: zimFileID)
            MacStreamingDownloadStore.save(updatedMetadata, for: zimFileID)
            return task
        } catch {
            if didAccess {
                folder.stopAccessingSecurityScopedResource()
            }
            throw error
        }
    }
    #endif

    private func resumeTask(
        _ task: URLSessionDownloadTask,
        zimFileID: UUID,
        destinationSnapshot: DownloadTaskDestinationSnapshot
    ) {
        DownloadTaskDestinationStore.save(destinationSnapshot, for: zimFileID)
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
        let (dataTasks, _, _) = await directSession.tasks
        if let task = dataTasks.first(where: { $0.taskDescription == zimFileID.uuidString }) {
            sessionDelegate.cancelMacStreamingTask(taskID: task.taskIdentifier)
            task.cancel()
        }
        if let metadata = MacStreamingDownloadStore.metadata(for: zimFileID) {
            let folder = metadata.destinationSnapshot.resolvedFolderURL()
            try? DownloadDestination.removeFileIfExists(at: metadata.partialFileURL, in: folder)
        }
        await downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
        #else
        let (_, _, downloadTasks) = await session.tasks
        if let task = downloadTasks.filter({ $0.taskDescription == zimFileID.uuidString }).first {
            task.cancel()
        }
        await downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
        #endif
    }

    /// Pause a zim file download task
    /// - Parameter zimFileID: identifier of the zim file
    func pause(zimFileID: UUID) {
        #if os(macOS)
        Task { @MainActor in
            let (dataTasks, _, _) = await directSession.tasks
            guard let task = dataTasks.first(where: { $0.taskDescription == zimFileID.uuidString }) else {
                return
            }
            sessionDelegate.cancelMacStreamingTask(taskID: task.taskIdentifier)
            task.cancel()
            progress.updateFor(uuid: zimFileID, withResumeData: MacStreamingDownloadStore.resumeData(for: zimFileID))
        }
        #else
        session.getTasksWithCompletionHandler { [progress] _, _, downloadTasks in
            guard let task = downloadTasks.filter({ $0.taskDescription == zimFileID.uuidString }).first else { return }
            task.cancel { [progress] resumeData in
                Task { @MainActor [progress] in
                    progress.updateFor(uuid: zimFileID, withResumeData: resumeData)
                }
            }
        }
        #endif
    }

    /// Resume a zim file download task and start heartbeat
    /// - Parameter zimFileID: identifier of the zim file
    func resume(zimFileID: UUID) async {
        requestNotificationAuthorization()

        guard let resumeData = progress.resumeDataFor(uuid: zimFileID) else { return }
        progress.updateFor(uuid: zimFileID, withResumeData: nil)

        await Database.shared.viewContext.perform {
            let request = DownloadTask.fetchRequest(fileID: zimFileID)
            request.fetchLimit = 1
            guard let downloadTask = try? request.execute().first else { return }
            downloadTask.error = nil
            let context = Database.shared.viewContext
            try? context.save()
        }

        #if os(macOS)
        guard let payload = try? JSONDecoder().decode(MacStreamingResumeData.self, from: resumeData) else {
            return
        }

        let folder = payload.destinationSnapshot.resolvedFolderURL()
        let destination = folder.appendingPathComponent(payload.destinationURL.lastPathComponent)
        let partialFileURL = DownloadDestination.partialFilePathFor(destination: destination)
        let downloadedBytes = MacStreamingDownloadStore.partialFileSize(at: partialFileURL)

        var request = URLRequest(url: payload.sourceURL)
        request.allowsCellularAccess = payload.allowsCellularAccess
        if downloadedBytes > 0 {
            request.setValue("bytes=\(downloadedBytes)-", forHTTPHeaderField: "Range")
            if let entityTag = payload.entityTag {
                request.setValue(entityTag, forHTTPHeaderField: "If-Range")
            } else if let lastModified = payload.lastModified {
                request.setValue(lastModified, forHTTPHeaderField: "If-Range")
            }
        }

        let metadata = MacStreamingDownloadMetadata(
            sourceURL: payload.sourceURL,
            allowsCellularAccess: payload.allowsCellularAccess,
            destinationSnapshot: payload.destinationSnapshot,
            destinationPath: destination.path(),
            partialFilePath: partialFileURL.path(),
            expectedTotalBytes: max(payload.expectedTotalBytes, downloadedBytes),
            entityTag: payload.entityTag,
            lastModified: payload.lastModified
        )

        do {
            let task = try makeMacStreamingTask(
                request: request,
                zimFileID: zimFileID,
                metadata: metadata,
                preservePartialFile: true
            )
            progress.updateFor(
                uuid: zimFileID,
                downloaded: downloadedBytes,
                total: max(metadata.expectedTotalBytes, downloadedBytes)
            )
            task.resume()
        } catch {
            progress.updateFor(uuid: zimFileID, withResumeData: resumeData)
        }
        #else
        let task = session.downloadTask(withResumeData: resumeData)
        task.taskDescription = zimFileID.uuidString
        task.resume()
        #endif
    }

    func allowsCellularAccessFor(zimFileID: UUID) async -> Bool? {
        #if os(macOS)
        let (dataTasks, _, _) = await directSession.tasks
        if let task = dataTasks.first(where: { $0.taskDescription == zimFileID.uuidString }) {
            return task.originalRequest?.allowsCellularAccess
        }
        return MacStreamingDownloadStore.metadata(for: zimFileID)?.allowsCellularAccess
        #else
        let (_, _, downloadTasks) = await session.tasks
        let task = downloadTasks.first(where: { $0.taskDescription == zimFileID.uuidString })
        return task?.originalRequest?.allowsCellularAccess
        #endif
    }

    // MARK: - Notification

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

// swiftlint:enable file_length
