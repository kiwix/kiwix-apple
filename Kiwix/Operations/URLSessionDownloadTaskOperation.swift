//
//  URLSessionDownloadTaskOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import ProcedureKit

class URLSessionDownloadTaskOperation: Procedure {
    
    enum KeyPath: String {
        case State = "state"
    }
    
    let task: URLSessionTask
    
    fileprivate(set) var produceResumeData = false
    fileprivate var removedObserved = false
    fileprivate let lock = NSLock()
    
    init(downloadTask: URLSessionDownloadTask) {
        self.task = downloadTask
        super.init()
        
        add(observer: NetworkObserver())
        addObserver(DidCancelObserver { _ in
            if self.produceResumeData {
                downloadTask.cancelByProducingResumeData({ _ in })
            } else {
                downloadTask.cancel()
            }
        })
    }
    
    func cancel(produceResumeData: Bool) {
        self.produceResumeData = produceResumeData
        cancel()
    }
    
    override func execute() {
        guard task.state == .suspended || task.state == .running else {
            finish()
            return
        }
        task.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions(), context: &URLSessionTaskOperationKVOContext)
        if task.state == .suspended {
            task.resume()
        }
    }
    
    override func
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [String : AnyObject]?, context: UnsafeMutableRawPointer) {
        guard context == &URLSessionTaskOperationKVOContext else { return }
        
        lock.withCriticalScope {
            if object === task && keyPath == KeyPath.State.rawValue && !removedObserved {
                
                if case .completed = task.state {
                    finish(task.error)
                }
                
                switch task.state {
                case .completed, .canceling:
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
    func withCriticalScope<T>(_ block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}
