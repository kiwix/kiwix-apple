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
    let sessionDelegate: URLSessionTaskDelegate
    let downloadManager: DownloadTaskManager
    private let queue: DispatchQueue
    private var heartbeat: Timer?
    
    private let session: URLSession
    
    private init() {
        queue = DispatchQueue(label: "downloads", qos: .background)
        progress = DownloadTasksPublisher()
        downloadManager = DownloadTaskManager(progress: progress)
#if os(iOS)
        sessionDelegate = IOSDownloadSessionDelegate(progress: progress,
                                                     downloadManager: downloadManager)
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.background")
#else
        sessionDelegate = MacOSDownloadDataDelegate(progress: progress,
                                                    downloadManager: downloadManager)
        let configuration = URLSessionConfiguration.default
#endif
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
    }
    
    // MARK: - Heartbeat
    
    /// Restart heartbeat if there are unfinished download task
    func restartHeartbeatIfNeeded() {
        session.getTasks { [weak progress] tasks in
            guard tasks.count > 0 else { return }
            for task in tasks {
                guard let zimFileID = task.zimFileID else { return }
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
    func start(zimFileID: UUID, allowsCellularAccess: Bool) async { // swiftlint:disable:this function_body_length
        requestNotificationAuthorization()
        let downloadStruct = await Database.shared.viewContext.perform { () -> DownloadZimStruct? in
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
        guard let downloadStruct else { return }
        let url = downloadStruct.url
        var urlRequest = URLRequest(url: url)
        urlRequest.allowsCellularAccess = allowsCellularAccess
#if os(iOS)
        let task: URLSessionTask = self.session.downloadTask(with: urlRequest)
#else
        let task: URLSessionTask = self.session.dataTask(with: urlRequest)
#endif
        task.countOfBytesClientExpectsToReceive = downloadStruct.size
        task.set(zimFileID: zimFileID)
        
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
    
    private func resumeTask(_ task: URLSessionTask, zimFileID: UUID) {
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
        await session.taskBy(zimFileID: zimFileID)?.cancel()
        await downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
    }
    
    /// Pause a zim file download task
    /// - Parameter zimFileID: identifier of the zim file
    func pause(zimFileID: UUID) {
#if os(iOS)
        sessionTaskBy(zimFileID: zimFileID) { [progress] task in
            guard let task else { return }
            task.cancel { [progress] resumeData in
                Task { @MainActor [progress] in
                    progress.updateFor(uuid: zimFileID, withResumeData: resumeData)
                }
            }
        }
#else
        session.taskBy(zimFileID: zimFileID) { [progress] task in
            guard let task else {
                return
            }
            task.cancel()
            Task { @MainActor [progress] in
                // faking the resume functionality
                // this data is not really used for anything
                // apart from knowing it's a paused state
                let fakeResume = "fake".data(using: .utf8)
                progress.updateFor(uuid: zimFileID, withResumeData: fakeResume)
            }
        }
#endif
        
    }
    
    /// Resume a zim file download task and start heartbeat
    /// - Parameter zimFileID: identifier of the zim file
    func resume(zimFileID: UUID) async {
        requestNotificationAuthorization()
#if os(iOS)
        await resumeiOS(zimFileID: zimFileID)
#else
        await resumeMacOS(zimFileID: zimFileID)
#endif
    }
    
#if os(iOS)
    private func resumeiOS(zimFileID: UUID) async {
        guard let resumeData = progress.resumeDataFor(uuid: zimFileID) else { return }
        progress.updateFor(uuid: zimFileID, withResumeData: nil)
        
        await Database.shared.viewContext.perform { [resumeData] in
            let request = DownloadTask.fetchRequest(fileID: zimFileID)
            request.fetchLimit = 1
            guard let downloadTask = try? request.execute().first else { return }
            
            let task = self.session.downloadTask(withResumeData: resumeData)
            task.set(zimFileID: zimFileID)
            task.resume()
            
            downloadTask.error = nil
            
            let context = Database.shared.viewContext
            try? context.save()
        }
    }
    
#else
    private func resumeMacOS(zimFileID: UUID) async {
        let offset = progress.offsetFor(uuid: zimFileID)
        progress.updateFor(uuid: zimFileID, withResumeData: nil)
        let context = Database.shared.viewContext
        
        // get the download URL, and reset any DownloadTask errors
        let downloadStruct = await context.perform { () -> DownloadZimStruct? in
            let fetchRequest = ZimFile.fetchRequest(fileID: zimFileID)
            fetchRequest.fetchLimit = 1
            guard let zimFile = try? fetchRequest.execute().first,
                  var url = zimFile.downloadURL else {
                return nil
            }
            if url.lastPathComponent.hasSuffix(".meta4") {
                url = url.deletingPathExtension()
            }
            let hasDownloadError = zimFile.downloadTask?.error != nil
            if hasDownloadError {
                zimFile.downloadTask?.error = nil
                if context.hasChanges {
                    try? context.save()
                }
            }
            return DownloadZimStruct(url: url, name: zimFile.name, size: zimFile.size)
        }
        
        // re-create the URLRequest and dataTask
        guard let downloadStruct else { return }
        let url = downloadStruct.url
        var urlRequest = URLRequest(url: url)
        // adjust the offset with a range request
        if let offset, 0 < offset {
            urlRequest.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
            Log.DownloadService.info("Requesting range from byte \(offset)")
        }
        let task: URLSessionTask = self.session.dataTask(with: urlRequest)
        task.countOfBytesClientExpectsToReceive = downloadStruct.size
        task.set(zimFileID: zimFileID)
        task.resume()
    }
#endif
    
    func allowsCellularAccessFor(zimFileID: UUID) async -> Bool? {
        let task = await session.taskBy(zimFileID: zimFileID)
        return task?.originalRequest?.allowsCellularAccess
    }
    
    // MARK: - Notification
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

// swiftlint:enable file_length
