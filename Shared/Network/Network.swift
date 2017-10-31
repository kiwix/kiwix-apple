//
//  Downloader.swift
//  Kiwix
//
//  Created by Chris Li on 1/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

class Network: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let shared = Network()
    
    private var progresses = [String: Int64]()
    private let managedObjectContext = CoreDataContainer.shared.viewContext
    private var timer: Timer?
    
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
            if hasTask && self.timer == nil {
                OperationQueue.main.addOperation({
                    self.startTimer()
                })
            }
        })
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.managedObjectContext.perform({
                for (bookID, bytesWritten) in self.progresses {
                    guard let book = Book.fetch(id: bookID, context: self.managedObjectContext) else {continue}
                    if bytesWritten > 0 {
                        if book.state != .downloading {book.state = .downloading}
                        book.totalBytesWritten = bytesWritten
                    } else {
                        if book.state != .downloadQueued {book.state = .downloadQueued}
                    }
                }
            })
        })
    }
    
    // MARK: - actions
    
    func start(bookID: String, allowsCellularAccess: Bool) {
        managedObjectContext.perform {
            guard let book = Book.fetch(id: bookID, context: self.managedObjectContext),
                let url = book.url else {return}
            
            var request = URLRequest(url: url)
            request.allowsCellularAccess = allowsCellularAccess
            let task = self.session.downloadTask(with: request)
            task.taskDescription = book.id
            task.resume()
            
            if self.timer == nil { self.startTimer() }
            NetworkActivityController.shared.taskDidStart(identifier: bookID)
            
            book.state = .downloadQueued
            if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
        }
    }
    
    func pause(bookID: String) {
        cancelTask(in: session, taskDescription: bookID, producingResumingData: true)
        
        self.managedObjectContext.perform({
            guard let book = Book.fetch(id: bookID, context: self.managedObjectContext) else {return}
            if book.state != .downloadPaused {book.state = .downloadPaused}
            if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
        })
    }
    
    func cancel(bookID: String) {
        cancelTask(in: session, taskDescription: bookID, producingResumingData: false)
        
        Preference.resumeData[bookID] = nil
        
        self.managedObjectContext.perform({
            guard let book = Book.fetch(id: bookID, context: self.managedObjectContext) else {return}
            book.meta4URL != nil ? book.state = .cloud : self.managedObjectContext.delete(book)
            if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
        })
    }
    
    func resume(bookID: String) {
        guard let data = Preference.resumeData[bookID] else {return}
        managedObjectContext.perform {
            guard let book = Book.fetch(id: bookID, context: self.managedObjectContext) else {return}
            let task = self.session.downloadTask(withResumeData: data)
            task.taskDescription = bookID
            task.resume()
            
            Preference.resumeData[bookID] = nil
            
            if self.timer == nil { self.startTimer() }
            NetworkActivityController.shared.taskDidStart(identifier: bookID)
            
            book.state = .downloadQueued
            if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
        }
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
        guard let bookID = task.taskDescription else {return}
        progresses[bookID] = nil
        if progresses.count == 0 { timer?.invalidate(); self.timer = nil }
        
        if let error = error as NSError? {
            self.managedObjectContext.perform({
                guard let book = Book.fetch(id: bookID, context: self.managedObjectContext) else {return}
                if error.code == URLError.cancelled.rawValue {
                    if let data = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        // task is resumable
                        Preference.resumeData[bookID] = data
                        book.state = .downloadPaused
                    } else {
                        // task is not resumable
                        book.meta4URL != nil ? book.state = .cloud : self.managedObjectContext.delete(book)
                    }
                } else {
                    book.state = .downloadError
                }
            })
        }
        
        if let handler = backgroundEventsCompleteProcessing {
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
        
//        managedObjectContext.perform {
//            guard let book = Book.fetch(id: bookID, context: self.managedObjectContext) else {return}
//            book.state = .local
//            if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
//
//            if Preference.Notifications.bookDownloadFinish {
//                AppNotification.shared.downloadFinished(bookID: book.id,
//                                                        bookTitle: book.title ?? "Book",
//                                                        fileSizeDescription: book.fileSizeDescription)
//            }
//        }
    }
}
