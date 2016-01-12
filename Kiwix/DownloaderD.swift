

//
//  DownloaderD.swift
//  Kiwix
//
//  Created by Chris on 12/16/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension Downloader: NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate {
    
    // MRK: - NSURLSessionTaskDelegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        taskCount--
        guard let id = task.taskDescription else {return}
        // Only set progress[id] to nil when a task finish successfully
        if error == nil {progresses[id] = nil}
    }
    
    // MARK: NSURLSessionDelegate
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            UIApplication.updateApplicationIconBadgeNumber()
            let localNotification = UILocalNotification()
            localNotification.alertBody = LocalizedStrings.allDownloadFinished
            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
            self.completionHandler?()
        }
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        guard let id = downloadTask.taskDescription else {return}
        guard let book = progresses[id]?.book else {return}
        NSFileManager.removeResumeData(book)
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        guard let id = downloadTask.taskDescription else {return}
        guard let book = progresses[id]?.book else {return}
        NSFileManager.move(book, fromURL: location, suggestedFileName: downloadTask.response?.suggestedFilename)
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            book.isLocal = true
            guard let downloadTask = book.downloadTask else {return}
            UIApplication.appDelegate.managedObjectContext.deleteObject(downloadTask)
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let id = downloadTask.taskDescription else {return}
        guard let progress = progresses[id] else {print("didn't find progress for id=\(id) in progresses"); return}
        guard let downloadTaskState = progress.book.downloadTask?.state else {return}
        progress.completedUnitCount = totalBytesWritten
        progress.updateSpeed(totalBytesWritten)
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            if downloadTaskState == .Queued {
                progress.book.downloadTask?.state = .Downloading
            } else if downloadTaskState == .Downloading {
                self.delegate?.progressUpdate(progress)
            }
        }
    }
    
}

extension LocalizedStrings {
    class var allDownloadFinished: String {return NSLocalizedString("All download tasks have finished.", comment: "Notification: Book Download Tasks Finshed")}
}