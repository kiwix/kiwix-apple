//
//  DownloadBookOperation.swift
//  Kiwix
//
//  Created by Chris Li on 8/25/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import Operations

class DownloadBookOperation: URLSessionDownloadTaskOperation {
    
    let progress: DownloadProgress
    
    override init(downloadTask: NSURLSessionDownloadTask) {
        progress = DownloadProgress(completedUnitCount: downloadTask.countOfBytesReceived, totalUnitCount: downloadTask.countOfBytesExpectedToReceive)
        super.init(downloadTask: downloadTask)
        name = downloadTask.taskDescription
    }
    
    convenience init?(bookID: String) {
        let context = NSManagedObjectContext.mainQueueContext
        guard let book = Book.fetch(bookID, context: context),
            let url = book.url else { return nil }

        let task = Network.shared.session.downloadTaskWithURL(url)
        task.taskDescription = bookID
        self.init(downloadTask: task)
        
        let downloadTask = DownloadTask.addOrUpdate(book, context: context)
        downloadTask?.state = .Queued
        book.isLocal = nil
        
        progress.completedUnitCount = book.downloadTask?.totalBytesWritten ?? 0
        progress.totalUnitCount = book.fileSize
    }
    
    override func operationWillCancel(errors: [ErrorType]) {
        print("Download Task will cancel")
    }
    
    override func operationDidCancel() {
        print("Download Task did cancel")
    }
}

class RemoveBookOperation: Operation {
    
    let bookID: String
    
    init(bookID: String) {
        self.bookID = bookID
        super.init()
    }
    
    override func execute() {
        let context = NSManagedObjectContext.mainQueueContext
        context.performBlockAndWait {
            guard let zimFileURL = ZimMultiReader.shared.readers[self.bookID]?.fileURL else {return}
            _ = try? NSFileManager.defaultManager().removeItemAtURL(zimFileURL)
            
            // Core data is updated by scan book operation
            // Article removal is handled by cascade relationship
            
            guard let idxFolderURL = ZimMultiReader.shared.readers[self.bookID]?.idxFolderURL else {return}
            _ = try? NSFileManager.defaultManager().removeItemAtURL(idxFolderURL)
        }
        finish()
    }
    
    
}

