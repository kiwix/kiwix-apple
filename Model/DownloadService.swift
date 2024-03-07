//
//  DownloadService.swift
//  Kiwix

import CoreData
import UserNotifications
import os

private final class DownloadProgress {
    private var dictionary = [UUID: Int64]()
    private let inSync = InSync(label: "org.kiwix.downloadProgress")

    func updateFor(uuid: UUID, totalBytes: Int64) {
        inSync.execute { [weak self] in
            self?.dictionary[uuid] = totalBytes
        }
    }

    func values() -> [UUID: Int64] {
        inSync.read { dictionary }
    }

    func resetFor(uuid: UUID) {
        inSync.execute { [weak self] in
            self?.dictionary.removeValue(forKey: uuid)
        }
    }

    func isEmpty() -> Bool {
        inSync.read { dictionary.isEmpty }
    }
}

final class DownloadService: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let shared = DownloadService()
    
    private let queue = DispatchQueue(label: "downloads")
    private let progress = DownloadProgress()
    private var heartbeat: Timer?
    
    var backgroundCompletionHandler: (() -> Void)?
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
        session.getTasksWithCompletionHandler { _, _, downloadTasks in
            guard downloadTasks.count > 0 else { return }
            for task in downloadTasks {
                guard let taskDescription = task.taskDescription,
                      let zimFileID = UUID(uuidString: taskDescription) else { return }
                self.progress.updateFor(uuid: zimFileID, totalBytes: task.countOfBytesReceived)
            }
            self.startHeartbeat()
        }
    }
    
    /// Start heartbeat, which will update database every 0.25 seconds
    private func startHeartbeat() {
        DispatchQueue.main.async {
            guard self.heartbeat == nil else { return }
            self.heartbeat = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
                Database.shared.container.performBackgroundTask { [weak self] context in
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    if let progressValues = self?.progress.values() {
                        for (zimFileID, downloadedBytes) in progressValues {
                            let predicate = NSPredicate(format: "fileID == %@", zimFileID as CVarArg)
                            let request = DownloadTask.fetchRequest(predicate: predicate)
                            guard let downloadTask = try? context.fetch(request).first else { return }
                            downloadTask.downloadedBytes = downloadedBytes
                        }
                        try? context.save()
                    }
                }
            }
            os_log("Heartbeat started.", log: Log.DownloadService, type: .info)
        }
    }
    
    /// Stop heartbeat, which stops periodical database update
    private func stopHeartbeat() {
        DispatchQueue.main.async {
            guard self.heartbeat != nil else { return }
            self.heartbeat?.invalidate()
            self.heartbeat = nil
            os_log("Heartbeat stopped.", log: Log.DownloadService, type: .info)
        }
    }
    
    // MARK: - Download Actions
    
    /// Start a zim file download task
    /// - Parameters:
    ///   - zimFile: the zim file to download
    ///   - allowsCellularAccess: if using cellular data is allowed
    func start(zimFileID: UUID, allowsCellularAccess: Bool) {
        requestNotificationAuthorization()
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            let fetchRequest = ZimFile.fetchRequest(fileID: zimFileID)
            guard let zimFile = try? context.fetch(fetchRequest).first,
                  var url = zimFile.downloadURL else { return }
            let downloadTask = DownloadTask(context: context)
            downloadTask.created = Date()
            downloadTask.fileID = zimFileID
            downloadTask.totalBytes = zimFile.size
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
        startHeartbeat()
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
        session.getTasksWithCompletionHandler { _, _, downloadTasks in
            guard let task = downloadTasks.filter({ $0.taskDescription == zimFileID.uuidString }).first else { return }
            task.cancel { resumeData in
                Database.shared.container.performBackgroundTask { context in
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    let request = DownloadTask.fetchRequest(fileID: zimFileID)
                    guard let downloadTask = try? context.fetch(request).first else { return }
                    downloadTask.resumeData = resumeData
                    try? context.save()
                }
            }
        }
    }
    
    /// Resume a zim file download task and start heartbeat
    /// - Parameter zimFileID: identifier of the zim file
    func resume(zimFileID: UUID) {
        requestNotificationAuthorization()
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            let request = DownloadTask.fetchRequest(fileID: zimFileID)
            guard let downloadTask = try? context.fetch(request).first,
                  let resumeData = downloadTask.resumeData else { return }
            
            let task = self.session.downloadTask(withResumeData: resumeData)
            task.taskDescription = zimFileID.uuidString
            task.resume()
            
            downloadTask.error = nil
            downloadTask.resumeData = nil
            try? context.save()
            
            self.startHeartbeat()
        }
    }
    
    // MARK: - Database
    
    private func deleteDownloadTask(zimFileID: UUID) {
        Database.shared.container.performBackgroundTask { context in
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
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func scheduleDownloadCompleteNotification(zimFileID: UUID) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus != .denied else { return }
            Database.shared.container.performBackgroundTask { context in
                // configure notification content
                let content = UNMutableNotificationContent()
                content.title = "download_service.complete.title".localized
                content.sound = .default
                if let zimFile = try? context.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first {
                    content.body = "download_service.complete.description".localizedWithFormat(withArgs: zimFile.name)
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
              let zimFileID = UUID(uuidString: taskDescription) else { return }
        progress.resetFor(uuid: zimFileID)
        if progress.isEmpty() {
            stopHeartbeat()
        }
        
        // download finished successfully if there's no error
        guard let error = error as NSError? else {
            self.deleteDownloadTask(zimFileID: zimFileID)
            os_log(
                "Download finished successfully. File ID: %s.",
                log: Log.DownloadService,
                type: .info,
                zimFileID.uuidString
            )
            return
        }
        
        /*
         Save the error description and resume data if there are new resule data
         Note: The result data equality check is used as a trick to distinguish user pausing the download task vs
         failure. When pausing, the same resume data would have already been saved when the delegate is called.
        */
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            let request = DownloadTask.fetchRequest(fileID: zimFileID)
            let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
            guard let downloadTask = try? context.fetch(request).first,
                  downloadTask.resumeData != resumeData else { return }
            downloadTask.error = error.localizedDescription
            downloadTask.resumeData = resumeData
            try? context.save()
        }
        os_log(
            "Download finished with error. File ID: %s. Error",
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
        progress.updateFor(uuid: zimFileID, totalBytes: totalBytesWritten)
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // determine which directory should the file be moved to
        #if os(macOS)
        let searchPath = FileManager.SearchPathDirectory.downloadsDirectory
        #elseif os(iOS)
        let searchPath = FileManager.SearchPathDirectory.documentDirectory
        #endif
        
        // move file
        guard let directory = FileManager.default.urls(for: searchPath, in: .userDomainMask).first,
            let zimFileID = UUID(uuidString: downloadTask.taskDescription ?? "") else {return}
        let fileName = downloadTask.response?.suggestedFilename
            ?? downloadTask.originalRequest?.url?.lastPathComponent
            ?? zimFileID.uuidString + ".zim"
        let destination = directory.appendingPathComponent(fileName)
        try? FileManager.default.moveItem(at: location, to: destination)
        
        // open the file
        LibraryOperations.open(url: destination)
        
        // schedule notification
        scheduleDownloadCompleteNotification(zimFileID: zimFileID)
    }
    
    // MARK: - URLSessionDelegate
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
        }
    }
}
