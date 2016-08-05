//
//  URLSessionDownloadTaskOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import PSOperations

private var URLSessionTaskOperationKVOContext = 0

public class URLSessionDownloadTaskOperation: Operation {
    let task: NSURLSessionDownloadTask
    private var produceResumeData = false
    private var observerRemoved = false
    private let stateLock = NSLock()
    
    public init(downloadTask: NSURLSessionDownloadTask) {
        self.task = downloadTask
        super.init()
        
        addObserver(BlockObserver(cancelHandler: { _ in
            if self.produceResumeData {
                downloadTask.cancelByProducingResumeData({ (data) in
                })
            } else {
                downloadTask.cancel()
            }
        }))
    }
    
    public func cancel(produceResumeData produceResumeData: Bool) {
        self.produceResumeData = produceResumeData
        cancel()
    }
    
    override public func execute() {
        guard task.state == .Suspended || task.state == .Running else {
            finish()
            return
        }
        task.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions(), context: &URLSessionTaskOperationKVOContext)
        if task.state == .Suspended {
            task.resume()
        }
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &URLSessionTaskOperationKVOContext else { return }
        
        stateLock.withCriticalScope {
            if object === task && keyPath == "state" && !observerRemoved {
                switch task.state {
                case .Completed:
                    finish()
                    fallthrough
                case .Canceling:
                    observerRemoved = true
                    task.removeObserver(self, forKeyPath: "state")
                default:
                    return
                }
            }
        }
    }
}

private extension NSLock {
    func withCriticalScope<T>(@noescape block: Void -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}