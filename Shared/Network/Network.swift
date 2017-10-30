//
//  Downloader.swift
//  Kiwix
//
//  Created by Chris Li on 1/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

class Network: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let shared = Network()
    let bookSizeThreshold: Int64 = 100000000
    
    var progresses = [String: Int64]()
    let managedObjectContext = CoreDataContainer.shared.viewContext
    var timer: Timer?
    
    lazy var wifiSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.wifi")
        configuration.allowsCellularAccess = false
        configuration.isDiscretionary = false
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    lazy var cellularSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.cellular")
        configuration.allowsCellularAccess = true
        configuration.isDiscretionary = false
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    var backgroundEventsCompleteProcessing = [String: () -> Void]()
    
    // MARK: - management
    
    private override init() {}
    
    func restorePreviousState() {
        var hasTask = false
        [wifiSession, cellularSession].forEach { (session) in
            session.getTasksWithCompletionHandler({ (_, _, downloadTasks) in
                downloadTasks.forEach({ (task) in
                    guard let bookID = task.taskDescription else {return}
                    hasTask = true
                    NetworkActivityController.shared.taskDidStart(identifier: bookID)
                })
            })
        }
        if hasTask && self.timer == nil {
            self.startTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.managedObjectContext.perform({
                for (bookID, bytesWritten) in self.progresses {
                    guard let book = Book.fetch(id: bookID, context: self.managedObjectContext) else {continue}
                    if book.state != .downloading {book.state = .downloading}
                    if bytesWritten > 0 {
                        if book.downloadTask?.state != .downloading {book.downloadTask?.state = .downloading; print("set state to downloading")}
                        book.downloadTask?.totalBytesWritten = bytesWritten
                    } else {
                        if book.downloadTask?.state != .queued {book.downloadTask?.state = .queued}
                    }
                }
            })
        })
    }
    
    // MARK: - actions
    
    func start(bookID: String, useWifiAndCellular: Bool?) {
        managedObjectContext.perform {
            guard let book = Book.fetch(id: bookID, context: self.managedObjectContext),
                let url = book.url else {return}
            let session: URLSession = {
                if let useWifiAndCellular = useWifiAndCellular {
                    return useWifiAndCellular ? self.cellularSession : self.wifiSession
                } else {
                    return book.fileSize > self.bookSizeThreshold ? self.wifiSession : self.cellularSession
                }
            }()
            let task = session.downloadTask(with: url)
            task.taskDescription = book.id
            task.resume()
            
            book.state = .downloading
            let downloadTask = DownloadTask.fetchAddIfNotExist(bookID: bookID, context: self.managedObjectContext)
            downloadTask?.state = .queued
            
            if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
            
            self.progresses[bookID] = 0
            if self.progresses.count == 1 { self.startTimer() }
            
            NetworkActivityController.shared.taskDidStart(identifier: bookID)
        }
    }
    
    func pause(bookID: String) {
        cancelTask(in: wifiSession, taskDescription: bookID, producingResumingData: true)
        cancelTask(in: cellularSession, taskDescription: bookID, producingResumingData: true)
        
        self.managedObjectContext.perform({
            guard let book = Book.fetch(id: bookID, context: self.managedObjectContext) else {return}
            if book.state != .downloading {book.state = .downloading}
            book.downloadTask?.state = .paused
            if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
        })
    }
    
    func cancel(bookID: String) {
        cancelTask(in: wifiSession, taskDescription: bookID, producingResumingData: false)
        cancelTask(in: cellularSession, taskDescription: bookID, producingResumingData: false)
        
        Preference.resumeData[bookID] = nil
        
        self.managedObjectContext.perform({
            guard let book = Book.fetch(id: bookID, context: self.managedObjectContext) else {return}
            book.meta4URL != nil ? book.state = .cloud : self.managedObjectContext.delete(book)
            if let downloadTask = book.downloadTask {self.managedObjectContext.delete(downloadTask)}
            if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
        })
    }
    
    func resume(bookID: String) {
        guard let data = Preference.resumeData[bookID] else {return}
        let bookSizeIsBig: Bool = {
            guard let size = Book.fetch(id: bookID, context: self.managedObjectContext)?.fileSize else {return true}
            return size > bookSizeThreshold
        }()
        let task = (bookSizeIsBig ? wifiSession : cellularSession).downloadTask(withResumeData: data)
        task.taskDescription = bookID
        task.resume()
        
        Preference.resumeData[bookID] = nil
        
        let downloadTask = DownloadTask.fetchAddIfNotExist(bookID: bookID, context: managedObjectContext)
        downloadTask?.state = .queued
        
        if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
        
        progresses[bookID] = 0
        if timer == nil { startTimer() }
        
        NetworkActivityController.shared.taskDidStart(identifier: bookID)
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
        if let error = error {print("Download error: \(error.localizedDescription)")}
        guard let bookID = task.taskDescription else {return}
        progresses[bookID] = nil
        if progresses.count == 0 { timer?.invalidate() }
        
        if let error = error as NSError? {
            self.managedObjectContext.perform({
                guard let book = Book.fetch(id: bookID, context: self.managedObjectContext) else {return}
                if error.code == URLError.cancelled.rawValue {
                    if let data = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        // task is resumable
                        Preference.resumeData[bookID] = data
                        book.downloadTask?.state = .paused
                    } else {
                        // task is not resumable
                        if let downloadTask = book.downloadTask {
                            self.managedObjectContext.delete(downloadTask)
                        }
                        if let _ = book.url {
                            book.state = .cloud
                        } else {
                            self.managedObjectContext.delete(book)
                        }
                    }
                } else {
                    book.downloadTask?.state = .error
                }
            })
        }
        
        if let identifier = session.configuration.identifier,
            let handler = backgroundEventsCompleteProcessing[identifier] {
            handler()
        }
        
        NetworkActivityController.shared.taskDidFinish(identifier: bookID)
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let bookID = downloadTask.taskDescription else {return}
        self.progresses[bookID] = totalBytesWritten
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let bookID = downloadTask.taskDescription else {return}
        
        if let docDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileName = {
                return downloadTask.response?.suggestedFilename
                    ?? downloadTask.originalRequest?.url?.lastPathComponent
                    ?? bookID + ".zim"
            }()
            let destination = docDirURL.appendingPathComponent(fileName)
            try? FileManager.default.moveItem(at: location, to: destination)
        }
        
        managedObjectContext.perform {
            guard let book = Book.fetch(id: bookID, context: self.managedObjectContext),
                let downloadTask = DownloadTask.fetchAddIfNotExist(bookID: bookID, context: self.managedObjectContext) else {return}
            book.state = .local
            self.managedObjectContext.delete(downloadTask)
            if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
            
            if Preference.Notifications.bookDownloadFinish {
//                AppNotification.shared.downloadFinished(bookID: book.id,
//                                                        bookTitle: book.title ?? "Book",
//                                                        fileSizeDescription: book.fileSizeDescription)
            }
        }
    }
}
