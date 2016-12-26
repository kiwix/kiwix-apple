//
//  DownloadManager.swift
//  Kiwix
//
//  Created by Chris Li on 12/25/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import ProcedureKit

class DownloadManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let shared = DownloadManager()
    let queue = ProcedureQueue()
    private override init() {
        super.init()
    }
    
    private(set) lazy var session: Foundation.URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.www")
        configuration.allowsCellularAccess = false
        configuration.isDiscretionary = false
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    
    
    // MARK: - URLSessionDelegate
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let operation = queue.operations.flatMap({$0 as? BookDownloadProcedure})
            .filter({$0.task.taskDescription == task.taskDescription})
            .first else {
                if let bookID = task.taskDescription,
                    let resumeData = (error as? NSError)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    let operation = BookDownloadProcedure(session: session, bookID: bookID, resumeData: resumeData)
                    DownloadManager.shared.queue.add(operation: operation)
                }
                return
        }
        if let error = error {
            operation.finish(withError: error)
        } else {
            operation.finish()
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }
}
