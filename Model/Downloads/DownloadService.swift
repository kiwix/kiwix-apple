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
    }
    
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
        let (_, _, downloadTasks) = await session.tasks
        if let task = downloadTasks.filter({ $0.taskDescription == zimFileID.uuidString }).first {
            task.cancel()
        }
        await downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
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
    func resume(zimFileID: UUID) {
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
