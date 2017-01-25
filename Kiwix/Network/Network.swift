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
    
    func start(book: Book) {
        guard let url = book.url else {return}
        let task = (book.fileSize > 100000000 ? wifiSession: cellularSession).downloadTask(with: url)
        task.taskDescription = book.id
        task.resume()
        
        let downloadTask = DownloadTask.fetch(bookID: book.id, context: managedObjectContext)
        downloadTask?.state = .queued
        
        progresses[book.id] = 0
        if progresses.count == 1 { startTimer() }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            for (bookID, bytesWritten) in self.progresses {
                guard let book = Book.fetch(bookID, context: self.managedObjectContext) else {continue}
                book.downloadTask?.totalBytesWritten = bytesWritten
            }
        })
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let bookID = downloadTask.taskDescription else {return}
        progresses[bookID] = bytesWritten
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        managedObjectContext.perform { 
            guard let bookID = downloadTask.taskDescription,
                let book = Book.fetch(bookID, context: self.managedObjectContext),
                let downloadTask = DownloadTask.fetch(bookID: bookID, context: self.managedObjectContext) else {return}
            //book.state = .local
            self.managedObjectContext.delete(downloadTask)
            print("finish downloading")
            
            self.progresses[bookID] = nil
            if self.progresses.count == 0 { self.timer?.invalidate() }
        }
        

    }
    
    
}
