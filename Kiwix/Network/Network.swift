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
import UserNotifications

class Network: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, OperationQueueDelegate  {
    static let shared = Network()
    let queue = OperationQueue()
    let context = NSManagedObjectContext.mainQueueContext
    
    private(set) var operations = [String: DownloadBookOperation]()
    private var downloadedBookTitle = [String]()
    private var completionHandler: (()-> Void)?
    
    private override init() {
        super.init()
        queue.delegate = self
        session.getAllTasksWithCompletionHandler { _ in }
    }
    
    lazy var session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.kiwix.www")
        configuration.allowsCellularAccess = false
        configuration.discretionary = false
        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    func rejoinSessionWithIdentifier(identifier: String, completionHandler: ()-> Void) {
        guard identifier == session.configuration.identifier else {return}
        self.completionHandler = completionHandler
    }
    
    // MARK: - OperationQueueDelegate
    
    func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation) {
        guard let bookID = operation.name,
            let operation = operation as? DownloadBookOperation else {return}
        operations[bookID] = operation
    }
    
    func operationQueue(queue: OperationQueue, didFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {
        guard let bookID = operation.name else {return}
        operations[bookID] = nil
    }
    
    func operationQueue(queue: OperationQueue, willFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {}
    
    func operationQueue(queue: OperationQueue, willProduceOperation operation: NSOperation) {}
    
    // MARK: - NSURLSessionDelegate
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.completionHandler?()
            
            let title = NSLocalizedString("Book download finished", comment: "Notification: Book download finished")
            let body: String = {
                switch self.downloadedBookTitle.count {
                case 0:
                    return NSLocalizedString("All download tasks are finished.", comment: "Notification: Book download finished")
                case 1:
                    return String(format: NSLocalizedString("%@ has been downloaded", comment: "Notification: Book download finished"), self.downloadedBookTitle[0])
                case 2:
                    return String(format: NSLocalizedString("%@ and @% have been downloaded", comment: "Notification: Book download finished"),
                                  self.downloadedBookTitle[0], self.downloadedBookTitle[1])
                default:
                    return String(format: NSLocalizedString("%@ and %d others have been downloaded", comment: "Notification: Book download finished"),
                                  self.downloadedBookTitle[0], self.downloadedBookTitle.count - 1)
                }
            }()
            
            if #available(iOS 10, *) {
                UNUserNotificationCenter.currentNotificationCenter().getNotificationSettingsWithCompletionHandler({ (settings) in
                    guard settings.alertSetting == .Enabled else {return}
                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                    let request = UNNotificationRequest(identifier: "org.kiwix.downloadFinished", content: content, trigger: trigger)
                    UNUserNotificationCenter.currentNotificationCenter().addNotificationRequest(request, withCompletionHandler: nil)
                })
            } else {
                let notification = UILocalNotification()
                notification.alertTitle = title
                notification.alertBody = body
                notification.soundName = UILocalNotificationDefaultSoundName
                UIApplication.sharedApplication().presentLocalNotificationNow(notification)
            }
        }
    }
    
    // MARK: - NSURLSessionTaskDelegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let error = error {print(error.localizedDescription)}
        
        let context = NSManagedObjectContext.mainQueueContext
        guard let error = error,
            let bookID = task.taskDescription,
            let downloadTask = Book.fetch(bookID, context: context)?.downloadTask else {return}
        
        if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? NSData {
            Preference.resumeData[bookID] = resumeData
            downloadTask.state = .Paused
            downloadTask.totalBytesWritten = task.countOfBytesReceived
        } else {
            downloadTask.state = .Error
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
        var fileName: String = downloadTask.response?.suggestedFilename ?? bookID
        if !fileName.hasSuffix(".zim") {fileName += ".zim"}
        guard let destination = NSFileManager.docDirURL.URLByAppendingPathComponent(fileName) else {return}
        _ = try? NSFileManager.defaultManager().moveItemAtURL(location, toURL: destination)
        
        // Scanner Operation will updated Book object status
        
        // - Remove cache, if any
        // - Delete Download task Object
        context.performBlockAndWait { 
            guard let book = Book.fetch(bookID, context: self.context) else {return}
            if let title = book.title {self.downloadedBookTitle.append(title)}
            book.removeResumeData()
            guard let downloadTask = book.downloadTask else {return}
            self.context.deleteObject(downloadTask)
        }
    }
}
