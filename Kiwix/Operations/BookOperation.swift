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
        
        progress.completedUnitCount = book.downloadTask?.totalBytesWritten ?? 0
        progress.totalUnitCount = book.fileSize
    }
    
}

class CancelBookDownloadOperation: Operation {
    
    let bookID: String
    
    init(bookID: String) {
        self.bookID = bookID
        super.init()
    }
    
    override func execute() {
        Network.shared.operations[bookID]?.cancel(produceResumeData: false)
        
        let context = NSManagedObjectContext.mainQueueContext
        context.performBlockAndWait {
            guard let book = Book.fetch(self.bookID, context: context) else {return}
            if let _ = book.meta4URL {
                book.isLocal = false
            } else{
                context.deleteObject(book)
            }
            
            guard let downloadTask = book.downloadTask else {return}
            context.deleteObject(downloadTask)
        }
        finish()
    }
}

class DownloadProgress: NSProgress {
    init(completedUnitCount: Int64, totalUnitCount: Int64) {
        super.init(parent: nil, userInfo: [NSProgressFileOperationKindKey: NSProgressFileOperationKindDownloading])
        self.kind = NSProgressKindFile
        self.totalUnitCount = totalUnitCount
        self.completedUnitCount = completedUnitCount
    }
}
