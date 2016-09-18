//
//  Network.swift
//  Kiwix
//
//  Created by Chris Li on 8/25/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import Operations

class Network: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, OperationQueueDelegate  {
    static let shared = Network()
    let queue = OperationQueue()
    let context = NSManagedObjectContext.mainQueueContext
    private(set) var operations = [String: DownloadBookOperation]()
    
    private override init() {
        super.init()
        queue.delegate = self
    }
    
    lazy var session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.kiwix.www")
        configuration.allowsCellularAccess = false
        configuration.discretionary = false
        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    // MARK: - OperationQueueDelegate
    
    func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation) {
        print("DEBUG: Network Queue will add " + (operation.name ?? "Unknown OP"))
        guard let bookID = operation.name,
            let operation = operation as? DownloadBookOperation else {return}
        operations[bookID] = operation
    }
    
    func operationQueue(queue: OperationQueue, willFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {}
    
    func operationQueue(queue: OperationQueue, didFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {
        print("DEBUG: Network Queue did finish " + (operation.name ?? "Unknown OP"))
        guard let bookID = operation.name else {return}
        operations[bookID] = nil
    }
    
    func operationQueue(queue: OperationQueue, willProduceOperation operation: NSOperation) {}
    
    // MARK: - NSURLSessionTaskDelegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        guard let error = error, let bookID = task.taskDescription else {return}
        self.context.performBlockAndWait {
            guard let book = Book.fetch(bookID, context: self.context),
                let downloadTask = book.downloadTask else {return}
            if error.code == NSURLErrorCancelled {
                // If download task doesnt exist, it must mean download is cancelled by user
                // DownloadTask object will have been deleted when user tap Cancel button / table row action
                downloadTask.totalBytesWritten = task.countOfBytesReceived
                downloadTask.state = .Paused
                
                // Save resue data to disk
                guard let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? NSData else {return}
                Preference.resumeData[bookID] = resumeData
            } else {
                downloadTask.state = .Error
            }
        }
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let bookID = downloadTask.taskDescription,
            let operation = operations[bookID] else {return}
        operation.progress.addObservation(totalBytesWritten)
        
        context.performBlock { 
            guard let downloadTask = Book.fetch(bookID, context: self.context)?.downloadTask where downloadTask.state == .Queued else {return}
            downloadTask.state = .Downloading
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        guard let bookID = downloadTask.taskDescription else {return}
        
        // Save downloaded zim file
        // Book object status will be updated by dir scanner
        var fileName: String = downloadTask.response?.suggestedFilename ?? bookID
        if !fileName.hasSuffix(".zim") {fileName += ".zim"}
        guard let destination = NSFileManager.docDirURL.URLByAppendingPathComponent(fileName) else {return}
        _ = try? NSFileManager.defaultManager().moveItemAtURL(location, toURL: destination)
        
        // Perform clean up (remove cache and delete download task)
        context.performBlock { 
            guard let book = Book.fetch(bookID, context: self.context) else {return}
            book.removeResumeData()
            guard let downloadTask = book.downloadTask else {return}
            self.context.deleteObject(downloadTask)
        }
    }
}
