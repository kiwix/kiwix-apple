//
//  Downloader.swift
//  Kiwix
//
//  Created by Chris Li on 1/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class Network: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let shared = Network()
    private override init() {}
    var progresses = [String: Int64]()
    let managedObjectContext = AppDelegate.persistentContainer.viewContext
    var timer: Timer?
    
    lazy var wifiSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.wifi")
        configuration.allowsCellularAccess = false
        configuration.isDiscretionary = false
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    lazy var cellularSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.cellular")
        configuration.allowsCellularAccess = true
        configuration.isDiscretionary = false
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    // MARK: - actions
    
    func start(bookID: String) {
        guard let book = Book.fetch(bookID, context: managedObjectContext), let url = book.url else {return}
        let task = (book.fileSize > 100000000 ? wifiSession: cellularSession).downloadTask(with: url)
        task.taskDescription = book.id
        task.resume()
        
        let downloadTask = DownloadTask.fetch(bookID: book.id, context: managedObjectContext)
        downloadTask?.state = .queued
        
        if self.managedObjectContext.hasChanges { try? self.managedObjectContext.save() }
        
        progresses[book.id] = 0
        if progresses.count == 1 { startTimer() }
    }
    
    func pause(bookID: String) {
        cancelTask(in: wifiSession, taskDescription: bookID, producingResumingData: true)
        cancelTask(in: cellularSession, taskDescription: bookID, producingResumingData: true)
    }
    
    func cancel(bookID: String) {
        cancelTask(in: wifiSession, taskDescription: bookID, producingResumingData: false)
        cancelTask(in: cellularSession, taskDescription: bookID, producingResumingData: false)
    }
    
    private func cancelTask(in session: URLSession, taskDescription: String, producingResumingData: Bool) {
        session.getTasksWithCompletionHandler { (_, _, downloadTasks) in
            func updateCoreData(bookID: String) {
                self.managedObjectContext.perform({
                    guard let book = Book.fetch(taskDescription, context: self.managedObjectContext) else {return}
                    if let _ = book.url {
                        book.state = .cloud
                    } else {
                        self.managedObjectContext.delete(book)
                    }
                    
                    guard let downloadTask = book.downloadTask else {return}
                    if producingResumingData {
                        downloadTask.state = .paused
                    } else {
                        self.managedObjectContext.delete(downloadTask)
                    }
                })
            }
            
            if let task = downloadTasks.filter({$0.taskDescription == taskDescription}).first {
                if producingResumingData {
                    task.cancel(byProducingResumeData: { (data) in
                        // save data
                        updateCoreData(bookID: taskDescription)
                    })
                } else {
                    task.cancel()
                    updateCoreData(bookID: taskDescription)
                }
            } else {
                updateCoreData(bookID: taskDescription)
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.managedObjectContext.perform({ 
                for (bookID, bytesWritten) in self.progresses {
                    guard let book = Book.fetch(bookID, context: self.managedObjectContext) else {continue}
                    book.downloadTask?.totalBytesWritten = bytesWritten
                }
            })
        })
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let bookID = task.taskDescription else {return}
        if let data = (error as NSError?)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            Preference.resumeData[bookID] = data
            self.managedObjectContext.perform({ 
                guard let book = Book.fetch(bookID, context: self.managedObjectContext) else {return}
                book.downloadTask?.state = .paused
            })
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        managedObjectContext.perform { 
            guard let bookID = downloadTask.taskDescription,
                let book = Book.fetch(bookID, context: self.managedObjectContext) else {return}
            if book.state != .downloading {book.state = .downloading}
            self.progresses[bookID] = totalBytesWritten
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let bookID = downloadTask.taskDescription else {return}
        
        progresses[bookID] = nil
        if progresses.count == 0 { timer?.invalidate() }
        
        if let docDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileName = {
                return downloadTask.response?.suggestedFilename
                    ?? downloadTask.originalRequest?.url?.lastPathComponent
                    ?? bookID
            }()
            let destination = docDirURL.appendingPathComponent(fileName)
            try? FileManager.default.moveItem(at: location, to: destination)
        }
        
        managedObjectContext.perform {
            guard let book = Book.fetch(bookID, context: self.managedObjectContext),
                let downloadTask = DownloadTask.fetch(bookID: bookID, context: self.managedObjectContext) else {return}
            book.state = .local
            self.managedObjectContext.delete(downloadTask)
        }
    }
}
