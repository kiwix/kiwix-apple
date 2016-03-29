//
//  Networking.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

let kiwixDownloaderURLSessionIdentifier = "org.kiwix.download"

class Downloader: NSObject, NSURLSessionDelegate {
    weak var delegate: DownloaderDelegate?
    let reachability: Reachability? = {do {return try Reachability.reachabilityForInternetConnection()} catch {return nil}}()
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    var progresses = [String: BookDownloadProgress]()
    
    var taskCount = 0 {
        willSet {UIApplication.appDelegate.networkTaskCount -= taskCount}
        didSet {UIApplication.appDelegate.networkTaskCount += taskCount}
    }
    var queuedTaskCount = 0
    
    override init() {
        super.init()
        configureReachibility()
        configureProcesses()
    }
    
    func configureReachibility() {
        guard let reachability = reachability else {return}
//        reachability.whenReachable = { reachibility in
//            dispatch_async(dispatch_get_main_queue()) {
//                if reachability.isReachableViaWiFi() {
//                    self.taskCount += self.queuedTaskCount
//                    self.queuedTaskCount = 0
//                } else {
//                    self.queuedTaskCount = self.taskCount
//                    self.taskCount = 0
//                }
//            }
//        }
//        reachability.whenUnreachable = { reachability in
//            dispatch_async(dispatch_get_main_queue()) {
//                self.queuedTaskCount = self.taskCount
//                self.taskCount = 0
//            }
//        }

        do {try reachability.startNotifier()} catch {print("Unable to start notifier")}
    }
    
    func configureProcesses() {
        session.getTasksWithCompletionHandler({ (dataTasks, uploadTasks, downloadTasks) -> Void in
            // for tasks that is not completed last time app is running
            // downloadTasks will contain on going tasks when user force quit the app / minimize the app
            for task in downloadTasks {
                guard let id = task.taskDescription else {continue}
                guard let book = Book.fetch(id, context: self.managedObjectContext) else {continue}
                let downloadTask = book.downloadTask ?? DownloadTask.addOrUpdate(book, context: self.managedObjectContext)
                
                if let resumeData = task.error?.userInfo[NSURLSessionDownloadTaskResumeData] as? NSData {
                    NSFileManager.saveResumeData(resumeData, book: book)
                    downloadTask?.state = .Paused
                } else {
                    downloadTask?.state = .Queued
                }
                
                downloadTask?.totalBytesWritten = task.countOfBytesReceived
                
                let progress = BookDownloadProgress(book: book)
                self.progresses[id] = progress
                self.taskCount++
            }
            
            // for tasks that already being paused when user last open the app
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                let downloadTasks = DownloadTask.fetchAll(self.managedObjectContext)
                for task in downloadTasks {
                    guard let book = task.book else {continue}
                    guard let id = book.id else {return}
                    if self.progresses[id] == nil {self.progresses[id] = BookDownloadProgress(book: book)}
                }
            })
        })
    }
    
    // MARK: - Tools
    
//    var canDownloadBook: Bool {
//        guard let reachability = reachability else {return false}
//        return reachability.currentReachabilityStatus == Reachability.NetworkStatus.ReachableViaWiFi ? true : false
//    }
    
    // MARK: - URLSession
    
    var completionHandler: (() -> Void)?
    
    lazy var session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(kiwixDownloaderURLSessionIdentifier)
        configuration.allowsCellularAccess = false
        configuration.discretionary = true
        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    func rejoinSessionWithIdentifier(identifier: String, completionHandler: () -> Void) {
        guard identifier == kiwixDownloaderURLSessionIdentifier else {return}
        self.completionHandler = completionHandler
    }
}

protocol DownloaderDelegate: class {
    func progressUpdate(progress: BookDownloadProgress)
}
