//
//  Network.swift
//  Kiwix
//
//  Created by Chris Li on 3/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import CoreData
import Operations

class Network: NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, OperationQueueDelegate {
    static let sharedInstance = Network()
    weak var delegate: DownloadProgressReporting?
    
    private let context = NSManagedObjectContext.mainQueueContext
    let operationQueue = OperationQueue()
    
    var progresses = [String: DownloadProgress]()
    private var timer: NSTimer?
    private var shouldReportProgress = false
    private var completionHandler: (()-> Void)?
    
    lazy var session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.kiwix.www")
        configuration.allowsCellularAccess = false
        configuration.discretionary = false
        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    override init() {
        super.init()
        operationQueue.delegate = self
    }
    
    func restoreProgresses() {
        let downloadTasks = DownloadTask.fetchAll(context)
        for downloadTask in downloadTasks {
            guard let book = downloadTask.book, let id = book.id else {continue}
            progresses[id] = DownloadProgress(book: book)
        }
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in
            for task in downloadTasks {
                let operation = URLSessionDownloadTaskOperation(downloadTask: task)
                operation.name = task.taskDescription
                operation.addObserver(NetworkObserver())
                self.operationQueue.addOperation(operation)
            }
        }
    }
    
    func rejoinSessionWithIdentifier(identifier: String, completionHandler: ()-> Void) {
        guard identifier == session.configuration.identifier else {return}
        self.completionHandler = completionHandler
    }
    
    func resetProgressReportingFlag() {shouldReportProgress = true}
    
    // MARK: - Tasks
    
    func download(book: Book) {
        guard let url = book.url else {return}
        book.isLocal = nil
        let task = session.downloadTaskWithURL(url)
        startTask(task, book: book)
    }
    
    func resume(book: Book) {
        guard let resumeData = FileManager.readResumeData(book) else {
            // TODO: Alert
            print("Could not resume, data mmissing / damaged")
            return
        }
        let task = session.downloadTaskWithResumeData(resumeData)
        startTask(task, book: book)
    }
    
    func pause(book: Book) {
        guard let id = book.id,
            let operation = operationQueue.getOperation(id) as? URLSessionDownloadTaskOperation else {return}
        operation.cancel(produceResumeData: true)
    }
    
    func cancel(book: Book) {
        guard let id = book.id,
            let operation = operationQueue.getOperation(id) as? URLSessionDownloadTaskOperation else {return}
        operation.cancel(produceResumeData: false)
    }
    
    private func startTask(task: NSURLSessionDownloadTask, book: Book) {
        guard let id = book.id else {return}
        task.taskDescription = id
        
        let downloadTask = DownloadTask.addOrUpdate(book, context: context)
        downloadTask?.state = .Queued
        
        let operation = URLSessionDownloadTaskOperation(downloadTask: task)
        operation.name = id
        operation.addObserver(NetworkObserver())
        operationQueue.addOperation(operation)
        
        let progress = DownloadProgress(book: book)
        progress.downloadStarted(task)
        progresses[id] = progress
    }
    
    // MARK: - OperationQueueDelegate
    
    func operationQueue(operationQueue: OperationQueue, willAddOperation operation: NSOperation) {
        guard operationQueue.operationCount == 0 else {return}
        shouldReportProgress = true
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(Network.resetProgressReportingFlag), userInfo: nil, repeats: true)
        }
    }
    
    func operationQueue(operationQueue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [NSError]) {
        guard operationQueue.operationCount == 1 else {return}
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.timer?.invalidate()
            self.shouldReportProgress = false
        }
    }
    
    // MARK: - NSURLSessionDelegate
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.completionHandler?()
            
            let notification = UILocalNotification()
            notification.alertTitle = NSLocalizedString("Book download finished", comment: "Notification: Book download finished")
            notification.alertBody = NSLocalizedString("All download tasks are finished.", comment: "Notification: Book download finished")
            notification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }
    
    // MARK: - NSURLSessionTaskDelegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        guard let error = error, let id = task.taskDescription,
            let progress = progresses[id], let downloadTask = progress.book.downloadTask else {return}
        progress.downloadTerminated()
        if error.code == NSURLErrorCancelled {
            context.performBlock({ () -> Void in
                downloadTask.state = .Paused
                guard let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? NSData else {
                    downloadTask.totalBytesWritten = 0
                    return
                }
                downloadTask.totalBytesWritten = Int64(task.countOfBytesReceived)
                progress.completedUnitCount = Int64(task.countOfBytesReceived)
                FileManager.saveResumeData(resumeData, book: progress.book)
            })
        }
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        guard let id = downloadTask.taskDescription,
              let book = progresses[id]?.book,
              let bookDownloadTask = book.downloadTask else {return}
        
        context.performBlockAndWait { () -> Void in
            self.context.deleteObject(bookDownloadTask)
        }
        
        progresses[id] = nil
        FileManager.move(book, fromURL: location, suggestedFileName: downloadTask.response?.suggestedFilename)
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let id = downloadTask.taskDescription,
              let downloadTask = progresses[id]?.book.downloadTask else {return}
        context.performBlockAndWait { () -> Void in
            guard downloadTask.state == .Queued else {return}
            downloadTask.state = .Downloading
        }
        
        guard shouldReportProgress else {return}
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.delegate?.refreshProgress()
        }
        shouldReportProgress = false
    }
}

protocol DownloadProgressReporting: class {
    func refreshProgress()
}
