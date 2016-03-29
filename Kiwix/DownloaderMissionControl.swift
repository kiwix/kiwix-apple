//
//  NetworkingMissionControl.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension Downloader {
    
    // MARK: - Start
    
    func startDownloadBook(book: Book) {
        guard let id = book.id else {return}
        let progress = BookDownloadProgress(book: book)
        
        guard let url = book.url else {return}
        let task = session.downloadTaskWithURL(url)
        task.taskDescription = id
        progress.task = task
        task.resume()
        taskCount++
        progresses[id] = progress
        
        let downloadTask = DownloadTask.addOrUpdate(book, context: UIApplication.appDelegate.managedObjectContext)
        downloadTask?.state = .Queued
        book.isLocal = nil
    }
    
    // MARK: - Resume
    
    func resumeDownloadBook(book: Book) {
        guard let id = book.id else {return}
        if let previousTask = progresses[id]?.task {previousTask.cancel()}
        book.downloadTask?.state = .Queued
        
        if let resumeData = NSFileManager.readResumeData(book) {
            let task = session.downloadTaskWithResumeData(resumeData)
            task.taskDescription = id
            task.resume()
            taskCount++
            let progress = progresses[id] ?? BookDownloadProgress(book: book)
            progress.task = task
            progresses[id] = progress
        } else {
            startDownloadBook(book)
        }
    }
    
    func resumeAllDownload() {
        
    }
    
    // MARK: - Pause
    
    func pauseDownloadBook(book: Book) {
        cancelDownloadBookAndProduceResumeData(book, shouldBeQueued: false)
    }
    
    func pauseAllDownload() {
        
    }
    
    // MARK: - Cancel
    
    func cancelDownloadBookAndProduceResumeData(book: Book, shouldBeQueued: Bool) {
        guard let id = book.id else {return}
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            book.downloadTask?.state = shouldBeQueued ? .Queued : .Paused
        })
        guard let progress = progresses[id] else {return}
        progress.task?.cancelByProducingResumeData { (resumeData) -> Void in
            guard let resumeData = resumeData else {return}
            NSFileManager.saveResumeData(resumeData, book: book)
            progress.resetSpeed()
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                book.downloadTask?.totalBytesWritten = progress.completedUnitCount
            })
        }
    }
    
    func cancelDownloadBookAndNotProduceResumeData(book: Book) {
        guard let id = book.id else {return}
        guard let progress = progresses[id] else {return}
        progress.task?.cancel()
        book.isLocal = false
    }
    
}