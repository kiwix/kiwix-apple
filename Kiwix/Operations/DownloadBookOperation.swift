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
    
    convenience init?(bookID: String) {
        let context = NSManagedObjectContext.mainQueueContext
        guard let book = Book.fetch(bookID, context: context),
            let url = book.url else { return nil }
        
//        book
        let task = Network.shared.session.downloadTaskWithURL(url)
        
        let downloadTask = DownloadTask.addOrUpdate(book, context: context)
        downloadTask?.state = .Queued
        
        task.taskDescription = bookID
        self.init(downloadTask: task)
    }
    
    override func operationDidFinish(errors: [ErrorType]) {
        guard let bookID = task.taskDescription else {return}
        print("Book download op finished")
    }
}

