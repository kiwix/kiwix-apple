//
//  DownloadService.swift
//  Kiwix
//
//  Created by Chris Li on 1/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import os
import RealmSwift

class DownloadService: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let shared = DownloadService()
    
    private let queue = DispatchQueue(label: "downloadServiceQueue")
    private var cachedTotalBytesWritten = [String: Int64]()
    private var heartbeat: Timer?
    var backgroundEventsProcessingCompletionHandler: (() -> Void)?
    
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
    
    /// When app is launched, restore state of network activity indicator and heartbeat if there are download task
    func restorePreviousState() {
        session.getTasksWithCompletionHandler({ (_, _, downloadTasks) in
            guard downloadTasks.count > 0 else { return }
            for task in downloadTasks {
                guard let zimFileID = task.taskDescription else {return}
                self.cachedTotalBytesWritten[zimFileID] = task.countOfBytesReceived
            }
            self.startHeartbeat()
        })
    }
    
    private func startHeartbeat() {
        DispatchQueue.main.async {
            guard self.heartbeat == nil else { return }
            self.heartbeat = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [unowned self] _ in
                self.saveCachedTotalBytesWritten()
            })
            os_log("Heartbeat started.", log: Log.DownloadService, type: .info)
        }
    }
    
    private func stopHeartbeat() {
        DispatchQueue.main.async {
            guard self.heartbeat != nil else { return }
            self.heartbeat?.invalidate()
            self.heartbeat = nil
            os_log("Heartbeat stopped.", log: Log.DownloadService, type: .info)
        }
    }
    
    /// Save the cached total bytes written data to database in one batch
    private func saveCachedTotalBytesWritten() {
        queue.async {
            let database = try? Realm()
            try? database?.write {
                self.cachedTotalBytesWritten.forEach { (zimFileID, bytes) in
                    guard let zimFile = database?.object(ofType: ZimFile.self, forPrimaryKey: zimFileID),
                          bytes > 0 else { return }
                    if zimFile.state != .downloadInProgress { zimFile.state = .downloadInProgress }
                    zimFile.downloadTotalBytesWritten = bytes
                }
            }
        }
    }
    
    // MARK: - perform download actions
    
    /// Start a zim file download task and start heartbeat
    /// - Parameters:
    ///   - zimFileID: identifier of the zim file
    ///   - allowsCellularAccess: if the file download allows using cellular data
    func start(zimFileID: String, allowsCellularAccess: Bool) {
        let database = try? Realm()
        guard let zimFile = database?.object(ofType: ZimFile.self, forPrimaryKey: zimFileID),
            var url = URL(string: zimFile.downloadURL ?? "") else {return}
        
        if url.lastPathComponent.hasSuffix(".meta4") {
            url = url.deletingPathExtension()
        }
        
        try? database?.write {
            zimFile.state = .downloadQueued
            zimFile.downloadResumeData = nil
            zimFile.downloadErrorDescription = nil
            zimFile.downloadTotalBytesWritten = 0
        }
        
        var request = URLRequest(url: url)
        request.allowsCellularAccess = allowsCellularAccess
        let task = self.session.downloadTask(with: request)
        task.taskDescription = zimFileID
        task.resume()
        
        self.startHeartbeat()
    }
    
    /// Resume a zim file download task and start heartbeat
    /// - Parameter zimFileID: identifier of the zim file
    func resume(zimFileID: String) {
        let database = try? Realm()
        guard let zimFile = database?.object(ofType: ZimFile.self, forPrimaryKey: zimFileID),
            let resumeData = zimFile.downloadResumeData else { return }
        
        try? database?.write {
            zimFile.state = .downloadQueued
            zimFile.downloadResumeData = nil
            zimFile.downloadErrorDescription = nil
        }
        
        let task = self.session.downloadTask(withResumeData: resumeData)
        task.taskDescription = zimFileID
        task.resume()
        
        self.startHeartbeat()
    }
    
    /// Pause a zim file download task
    /// - Parameter zimFileID: identifier of the zim file
    func pause(zimFileID: String) {
        session.getTasksWithCompletionHandler { (_, _, downloadTasks) in
            guard let task = downloadTasks.filter({ $0.taskDescription == zimFileID }).first else {return}
            task.cancel(byProducingResumeData: {data in })
        }
    }
    
    /// Cancel a zim file download task
    /// - Parameter zimFileID: identifier of the zim file
    func cancel(zimFileID: String) {
        session.getTasksWithCompletionHandler { (_, _, downloadTasks) in
            if let task = downloadTasks.filter({ $0.taskDescription == zimFileID }).first {
                task.cancel()
            } else {
                guard let database = try? Realm(),
                    let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else { return }
                try? database.write {
                    zimFile.state = .remote
                    zimFile.downloadResumeData = nil
                    zimFile.downloadTotalBytesWritten = 0
                    os_log("Task cancelled. File ID: %s", log: Log.DownloadService, type: .info, zimFileID)
                }
            }
        }
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let zimFileID = task.taskDescription else { return }
        cachedTotalBytesWritten[zimFileID] = nil
        if cachedTotalBytesWritten.count == 0 { stopHeartbeat() }
        
        if let error = error as NSError? {
            let database = try? Realm()
            guard let zimFile = database?.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else {return}
            
            try? database?.write {
                if error.code == URLError.cancelled.rawValue {
                    if let data = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        // task is paused
                        zimFile.state = .downloadPaused
                        zimFile.downloadResumeData = data
                        zimFile.downloadTotalBytesWritten = task.countOfBytesReceived
                        os_log("Task paused. File ID: %s", log: Log.DownloadService, type: .info, zimFileID)
                    } else {
                        // task is cancelled
                        zimFile.state = .remote
                        zimFile.downloadResumeData = nil
                        zimFile.downloadTotalBytesWritten = 0
                        os_log("Task cancelled. File ID: %s", log: Log.DownloadService, type: .info, zimFileID)
                    }
                } else {
                    // some other error happened
                    zimFile.state = .downloadError
                    zimFile.downloadErrorDescription = error.localizedDescription
                    if let data = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        zimFile.downloadResumeData = data
                        zimFile.downloadTotalBytesWritten = task.countOfBytesReceived
                    } else {
                        zimFile.downloadTotalBytesWritten = 0
                    }
                    os_log(
                        "Task errored. File ID: %s. Error",
                        log: Log.DownloadService,
                        type: .error,
                        zimFileID, error.localizedDescription
                    )
                }
            }
        } else {
            os_log("Task finished successfully. File ID: %s.", log: Log.DownloadService, type: .info, zimFileID)
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundEventsProcessingCompletionHandler?()
        }
        os_log("All background task events have been delivered.", log: Log.DownloadService, type: .info)
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64)
    {
        guard let zimFileID = downloadTask.taskDescription else {return}
        self.cachedTotalBytesWritten[zimFileID] = totalBytesWritten
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            let zimFileID = downloadTask.taskDescription else {return}
        
        let fileName = {
            return downloadTask.response?.suggestedFilename
                ?? downloadTask.originalRequest?.url?.lastPathComponent
                ?? zimFileID + ".zim"
        }()
        let destination = documentDirectory.appendingPathComponent(fileName)
        try? FileManager.default.moveItem(at: location, to: destination)
    }
}

