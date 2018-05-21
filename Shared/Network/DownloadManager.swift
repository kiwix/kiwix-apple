//
//  DownloadManager.swift
//  Kiwix
//
//  Created by Chris Li on 1/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import RealmSwift

class DownloadManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let shared = DownloadManager()
    
    private var totalBytesWritten = [String: Int64]() // for all download in progress zim files
    private var heartbeat: Timer?
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.background")
        configuration.allowsCellularAccess = true
        configuration.isDiscretionary = false
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    var backgroundEventsCompleteProcessing: (() -> Void)?
    
    // MARK: - management
    
    private override init() {}
    
    func restorePreviousState() {
        session.getTasksWithCompletionHandler({ (_, _, downloadTasks) in
            var hasTask = false
            downloadTasks.forEach({ (task) in
                guard let bookID = task.taskDescription else {return}
                hasTask = true
                NetworkActivityController.shared.taskDidStart(identifier: bookID)
            })
            if hasTask && self.heartbeat == nil {
                OperationQueue.main.addOperation({
                    self.startHeartbeat()
                })
            }
        })
    }
    
    private func startHeartbeat() {
        heartbeat = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            do {
                let database = try Realm(configuration: Realm.defaultConfig)
                try database.write {
                    for (zimFileID, bytesCount) in self.totalBytesWritten {
                        guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else {return}
                        if bytesCount > 0 && zimFile.state != .downloadInProgress {
                            zimFile.state = .downloadInProgress
                        }
                        zimFile.downloadTotalBytesWritten = bytesCount
                    }
                }
            } catch {}
        })
    }
    
    // MARK: - actions
    
    func start(zimFileID: String, allowsCellularAccess: Bool) {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID),
                let remoteURLString = zimFile.remoteURL, var url = URL(string: remoteURLString) else {return}
            if url.lastPathComponent.hasSuffix(".meta4") {
                url = url.deletingPathExtension()
            }
            
            try database.write {
                zimFile.state = .downloadQueued
            }
            
            var request = URLRequest(url: url)
            request.allowsCellularAccess = allowsCellularAccess
            let task = self.session.downloadTask(with: request)
            task.taskDescription = zimFileID
            task.resume()
            
            if self.heartbeat == nil { self.startHeartbeat() }
            NetworkActivityController.shared.taskDidStart(identifier: zimFileID)
        } catch {}
    }
    
    func pause(zimFileID: String) {
        cancelTask(in: session, taskDescription: zimFileID, producingResumingData: true)
    }
    
    func cancel(zimFileID: String) {
        cancelTask(in: session, taskDescription: zimFileID, producingResumingData: false)
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else {return}
            
            try database.write {
                zimFile.state = .cloud
                zimFile.downloadResumeData = nil
                zimFile.downloadTotalBytesWritten = 0
            }
        } catch {}
    }
    
    func resume(zimFileID: String) {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID),
                let resumeData = zimFile.downloadResumeData else {return}
            
            try database.write {
                zimFile.state = .downloadQueued
                zimFile.downloadResumeData = nil
                zimFile.downloadErrorDescription = nil
            }
            
            let task = self.session.downloadTask(withResumeData: resumeData)
            task.taskDescription = zimFileID
            task.resume()
            
            if self.heartbeat == nil { self.startHeartbeat() }
            NetworkActivityController.shared.taskDidStart(identifier: zimFileID)
        } catch {}
    }
    
    private func cancelTask(in session: URLSession, taskDescription: String, producingResumingData: Bool) {
        session.getTasksWithCompletionHandler { (_, _, downloadTasks) in
            guard let task = downloadTasks.filter({$0.taskDescription == taskDescription}).first else {return}
            if producingResumingData {
                task.cancel(byProducingResumeData: {data in Preference.resumeData[taskDescription] = data })
            } else {
                task.cancel()
            }
        }
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let zimFileID = task.taskDescription else {return}
        totalBytesWritten[zimFileID] = nil
        if totalBytesWritten.count == 0 { heartbeat?.invalidate(); self.heartbeat = nil }
        
        if let error = error as NSError? {
            do {
                let database = try Realm(configuration: Realm.defaultConfig)
                guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else {return}
                
                try database.write {
                    if error.code == URLError.cancelled.rawValue {
                        if let data = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                            // task is paused
                            zimFile.state = .downloadPaused
                            zimFile.downloadResumeData = data
                            zimFile.downloadTotalBytesWritten = task.countOfBytesReceived
                        } else {
                            // task is cancelled
                            zimFile.state = .cloud
                            zimFile.downloadResumeData = nil
                            zimFile.downloadTotalBytesWritten = 0
                        }
                    } else {
                        // other error happened
                        zimFile.state = .downloadError
                        zimFile.downloadErrorDescription = error.localizedDescription
                        if let data = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                            zimFile.downloadResumeData = data
                            zimFile.downloadTotalBytesWritten = task.countOfBytesReceived
                        } else {
                            zimFile.downloadTotalBytesWritten = 0
                        }
                    }
                }
            } catch {}
        }
        
        backgroundEventsCompleteProcessing?()
        NetworkActivityController.shared.taskDidFinish(identifier: zimFileID)
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let zimFileID = downloadTask.taskDescription else {return}
        self.totalBytesWritten[zimFileID] = totalBytesWritten
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
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

