//
//  URLSessionDownloadTaskOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Operations

class URLSessionDownloadTaskOperation: Operation {
    
    enum KeyPath: String {
        case State = "state"
    }
    
    let task: NSURLSessionTask
    
    private(set) var produceResumeData = false
    private var removedObserved = false
    private let lock = NSLock()
    
    init(downloadTask: NSURLSessionDownloadTask) {
        self.task = downloadTask
        super.init()
        
        addObserver(NetworkObserver())
        addObserver(DidCancelObserver { _ in
            if self.produceResumeData {
                downloadTask.cancelByProducingResumeData({ (data) in })
            } else {
                downloadTask.cancel()
            }
            }
        )
    }
    
    func cancel(produceResumeData produceResumeData: Bool) {
        self.produceResumeData = produceResumeData
        cancel()
    }
    
    override func execute() {
        guard task.state == .Suspended || task.state == .Running else {
            finish()
            return
        }
        task.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions(), context: &URLSessionTaskOperationKVOContext)
        if task.state == .Suspended {
            task.resume()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &URLSessionTaskOperationKVOContext else { return }
        
        lock.withCriticalScope {
            if object === task && keyPath == KeyPath.State.rawValue && !removedObserved {
                
                if case .Completed = task.state {
                    finish(task.error)
                }
                
                switch task.state {
                case .Completed, .Canceling:
                    task.removeObserver(self, forKeyPath: KeyPath.State.rawValue)
                    removedObserved = true
                default:
                    break
                }
            }
        }
    }
}

// swiftlint:disable variable_name
private var URLSessionTaskOperationKVOContext = 0
// swiftlint:enable variable_name

extension NSLock {
    func withCriticalScope<T>(@noescape block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}
