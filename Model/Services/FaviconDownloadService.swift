//
//  FaviconDownloadService.swift
//  Kiwix
//
//  Created by Chris Li on 8/23/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import os
import RealmSwift

class FaviconDownloadService: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    static let shared = FaviconDownloadService()
    
    private let queue = DispatchQueue(label: "org.kiwix.faviconDownload")
    private var cache = [String: Data]()
    private var retryCounter = [String: Int]()
    
    private lazy var session: URLSession = {
        var configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 1
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue
        return URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
    }()
    
    private override init() { }
    
    func download(zimFile: ZimFile) {
        guard let faviconURL = zimFile.faviconURL, let url = URL(string: faviconURL) else { return }
        let task = session.dataTask(with: url)
        task.taskDescription = zimFile.fileID
        task.resume()
    }
    
    private func retry(zimFileID: String) {
        guard retryCounter[zimFileID, default: 0] < 3 else { return }
        os_log("Retry downloading favicon data: %@.", log: Log.FaviconDownloadService, type: .info, zimFileID)
        retryCounter[zimFileID, default: 0] += 1
        queue.asyncAfter(deadline: DispatchTime.now() + 5) {
            guard let database = try? Realm(),
                  let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else { return }
            self.download(zimFile: zimFile)
        }
    }
    
    // MARK: - Delegates
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let zimFileID = dataTask.taskDescription else { return }
        var faviconData = cache[zimFileID, default: Data()]
        faviconData.append(data)
        cache[zimFileID] = faviconData
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let zimFileID = task.taskDescription else { return }
        defer { cache[zimFileID] = nil }
        
        // retry download later if request was unsuccessful
        guard let response = task.response as? HTTPURLResponse, response.statusCode == 200 else {
            retry(zimFileID: zimFileID)
            return
        }
        
        // save favicon data to database
        do {
            let database = try Realm()
            try database.write {
                guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else { return }
                zimFile.faviconData = cache[zimFileID]
            }
        } catch {
            os_log("Failed to save favicon data.", log: Log.FaviconDownloadService, type: .error)
        }
    }
}
