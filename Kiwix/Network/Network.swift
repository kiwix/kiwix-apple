//
//  Network.swift
//  Kiwix
//
//  Created by Chris Li on 8/25/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import ProcedureKit
import UserNotifications

class Network: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate, ProcedureQueueDelegate  {
    static let shared = Network()
    let queue = OperationQueue()
    let context = NSManagedObjectContext.mainQueueContext
    
    fileprivate(set) var operations = [String: DownloadBookOperation]()
    fileprivate var downloadedBookTitle = [String]()
    fileprivate var completionHandler: (()-> Void)?
    
    fileprivate override init() {
        super.init()
        queue.delegate = self
        session.getAllTasks { _ in }
    }
    
    lazy var session: Foundation.URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.www")
        configuration.allowsCellularAccess = false
        configuration.isDiscretionary = false
        return Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    func rejoinSessionWithIdentifier(_ identifier: String, completionHandler: @escaping ()-> Void) {
        guard identifier == session.configuration.identifier else {return}
        self.completionHandler = completionHandler
    }
    
    // MARK: - OperationQueueDelegate
    
    func operationQueue(_ queue: ProcedureQueue, willAddOperation operation: Procedure) {
        guard let bookID = operation.name,
            let operation = operation as? DownloadBookOperation else {return}
        operations[bookID] = operation
    }
    
    func operationQueue(_ queue: ProcedureQueue, didFinishOperation operation: Procedure, withErrors errors: [Error]) {
        guard let bookID = operation.name else {return}
        operations[bookID] = nil
    }
    
    func operationQueue(_ queue: ProcedureQueue, willFinishOperation operation: Procedure, withErrors errors: [Error]) {}
    
    func operationQueue(_ queue: ProcedureQueue, willProduceOperation operation: Procedure) {}
    
    // MARK: - NSURLSessionDelegate
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        OperationQueue.main.addOperation {
            self.completionHandler?()
            
            let title = NSLocalizedString("Book download finished", comment: "Notification: Book download finished")
            let body: String = {
                switch self.downloadedBookTitle.count {
                case 0:
                    return NSLocalizedString("All download tasks are finished.", comment: "Notification: Book download finished")
                case 1:
                    return String(format: NSLocalizedString("%@ has been downloaded", comment: "Notification: Book download finished"), self.downloadedBookTitle[0])
                case 2:
                    return String(format: NSLocalizedString("%@ and %@ have been downloaded", comment: "Notification: Book download finished"),
                                  self.downloadedBookTitle[0], self.downloadedBookTitle[1])
                default:
                    return String(format: NSLocalizedString("%@ and %d others have been downloaded", comment: "Notification: Book download finished"),
                                  self.downloadedBookTitle[0], self.downloadedBookTitle.count - 1)
                }
            }()
            
            if #available(iOS 10, *) {
                UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
                    guard settings.alertSetting == .enabled else {return}
                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                    let request = UNNotificationRequest(identifier: "org.kiwix.downloadFinished", content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                })
            } else {
                let notification = UILocalNotification()
                notification.alertTitle = title
                notification.alertBody = body
                notification.soundName = UILocalNotificationDefaultSoundName
                UIApplication.shared.presentLocalNotificationNow(notification)
            }
        }
    }
    
    // MARK: - NSURLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {print(error.localizedDescription)}
        
        let context = NSManagedObjectContext.mainQueueContext
        guard let error = error,
            let bookID = task.taskDescription,
            let downloadTask = Book.fetch(bookID, context: context)?.downloadTask else {return}
        
        if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            Preference.resumeData[bookID] = resumeData
            downloadTask.state = .paused
            downloadTask.totalBytesWritten = task.countOfBytesReceived
        } else {
            downloadTask.state = .error
        }
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let bookID = downloadTask.taskDescription,
            let operation = operations[bookID] else {return}
        operation.progress.addObservation(totalBytesWritten)
        
        context.perform { 
            guard let downloadTask = Book.fetch(bookID, context: self.context)?.downloadTask, downloadTask.state == .queued else {return}
            downloadTask.state = .downloading
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let bookID = downloadTask.taskDescription else {return}
        
        // Save downloaded zim file
        var fileName: String = downloadTask.response?.suggestedFilename ?? bookID
        if !fileName.hasSuffix(".zim") {fileName += ".zim"}
        guard let destination = FileManager.docDirURL.appendingPathComponent(fileName) else {return}
        _ = try? FileManager.default.moveItem(at: location, to: destination)
        
        // Scanner Operation will updated Book object status
        
        // - Remove cache, if any
        // - Delete Download task Object
        context.performAndWait { 
            guard let book = Book.fetch(bookID, context: self.context) else {return}
            if let title = book.title {self.downloadedBookTitle.append(title)}
            book.removeResumeData()
            guard let downloadTask = book.downloadTask else {return}
            self.context.delete(downloadTask)
        }
    }
}
