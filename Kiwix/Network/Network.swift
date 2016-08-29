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
        print(error?.code)
        print(error?.localizedDescription)
        print(error?.userInfo.keys)
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let bookID = downloadTask.taskDescription,
            let operation = operations[bookID] else {return}
        operation.progress.completedUnitCount = totalBytesWritten
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
        let context = NSManagedObjectContext.mainQueueContext
        context.performBlock { 
            guard let book = Book.fetch(bookID, context: context) else {return}
            book.removeCache()
            guard let downloadTask = book.downloadTask else {return}
            context.deleteObject(downloadTask)
        }
    }
}
