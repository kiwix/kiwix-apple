//
//  Downloads.swift
//  Kiwix
//
//  Created by Chris Li on 4/30/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import os
import CoreData

class Downloads: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let shared = Downloads()
    
    private let queue = DispatchQueue(label: "downloads")
    private var totalBytesWritten = [UUID: Int64]()
    private var heartbeat: Timer?
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.background")
        configuration.allowsCellularAccess = true
        configuration.isDiscretionary = false
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue
        return URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
    }()
    
    // MARK: - management
    
    private override init() {}
    
    /// When app is launched, restore heartbeat & total bytes written if there are download task
    func restorePreviousState() {
        session.getTasksWithCompletionHandler { _, _, downloadTasks in
            guard downloadTasks.count > 0 else { return }
            for task in downloadTasks {
                guard let taskDescription = task.taskDescription,
                      let zimFileID = UUID(uuidString: taskDescription) else {return}
                self.totalBytesWritten[zimFileID] = task.countOfBytesReceived
            }
            self.startHeartbeat()
        }
    }
    
    /// Start heartbeat, which will update database every second
    private func startHeartbeat() {
        DispatchQueue.main.async {
            guard self.heartbeat == nil else { return }
            self.heartbeat = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                let context = Database.shared.container.newBackgroundContext()
                context.perform {
                    for (zimFileID, downloadedBytes) in self.totalBytesWritten {
                        let predicate = NSPredicate(format: "fileID == %@", zimFileID as CVarArg)
                        let request = DownloadTask.fetchRequest(predicate: predicate)
                        guard let downloadTask = try? context.fetch(request).first else { return }
                        downloadTask.downloadedBytes = downloadedBytes
                    }
                    try? context.save()
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
    
    // MARK: - download actions
    
    /// Start a zim file download task
    /// - Parameters:
    ///   - zimFile: the zim file to download
    ///   - allowsCellularAccess: if using cellular data is allowed
    func start(zimFileID: UUID, allowsCellularAccess: Bool) {
        let context = Database.shared.container.newBackgroundContext()
        context.perform {
            let request = ZimFile.fetchRequest(fileID: zimFileID)
            guard let zimFile = try? context.fetch(request).first,
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
            print(url)
        }        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    }
}
