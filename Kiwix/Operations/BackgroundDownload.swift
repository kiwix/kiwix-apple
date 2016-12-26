//
//  BookDownload.swift
//  Kiwix
//
//  Created by Chris Li on 12/25/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import ProcedureKit

class BackgroundDownloadProcedure: Procedure {
    let task: URLSessionDownloadTask
    let resumeDataProcessing: (Data?) -> Void
    private let stateLock = NSLock()
    private var produceResumeData = false
    
    init(task: URLSessionDownloadTask, resumeData: @escaping (Data?) -> Void) {
        self.task = task
        self.resumeDataProcessing = resumeData
        super.init()
        
        add(observer: NetworkObserver())
        addDidCancelBlockObserver { procedure, errors in
            procedure.stateLock.withCriticalScope {
                if procedure.produceResumeData {
                    procedure.task.cancel(byProducingResumeData: self.resumeDataProcessing)
                } else {
                    procedure.task.cancel()
                }
            }
        }
    }
    
    override func execute() {
        stateLock.withCriticalScope {
            guard !isCancelled, task.state == .suspended else { return }
            task.resume()
        }
    }
    
    func pause() {
        produceResumeData = true
        cancel()
    }
}

class BookDownloadProcedure: BackgroundDownloadProcedure {
    
    init(task: URLSessionDownloadTask) {
        super.init(task: task) { data in
            print("cancelled, resume data length = \(data?.count)")
        }
        addDidFinishBlockObserver { (procedure, errors) in
            print("Download has finished")
        }
    }
    
    convenience init(session: URLSession, bookID: String, url: URL) {
        let task = session.downloadTask(with: url)
        task.taskDescription = bookID
        self.init(task: task)
    }
    
    convenience init(session: URLSession, bookID: String, resumeData: Data) {
        let task = session.downloadTask(withResumeData: resumeData)
        task.taskDescription = bookID
        self.init(task: task)
    }
    
    override func execute() {
        let context = AppDelegate.persistentContainer.viewContext
        context.performAndWait { 
            guard let bookID = self.task.taskDescription,
                let book = Book.fetch(bookID, context: context),
                let downloadTask = DownloadTask.fetch(book: book, context: context) else {return}
            downloadTask.state = .queued
        }
        super.execute()
    }
}
