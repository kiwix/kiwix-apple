/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Shows how to lift operation-like objects in to the NSOperation world.
*/

import Foundation

private var URLSessionTaskOperationKVOContext = 0

/**
    `URLSessionTaskOperation` is an `Operation` that lifts an `NSURLSessionTask` 
    into an operation.

    Note that this operation does not participate in any of the delegate callbacks \
    of an `NSURLSession`, but instead uses Key-Value-Observing to know when the
    task has been completed. It also does not get notified about any errors that
    occurred during execution of the task.

    An example usage of `URLSessionTaskOperation` can be seen in the `DownloadEarthquakesOperation`.
*/
public class URLSessionTaskOperation: Operation {
    let task: NSURLSessionTask
    var produceResumeDataWhenCancel: Bool
    
    private var observerRemoved = false
    private let stateLock = NSLock()
    
    public init(task: NSURLSessionTask, produceResumeDataWhenCancel: Bool = false) {
        assert(task.state == .Suspended, "Tasks must be suspended.")
        self.task = task
        self.produceResumeDataWhenCancel = produceResumeDataWhenCancel
        super.init()
        
        addObserver(BlockObserver(cancelHandler: { _ in
            if let task = task as? NSURLSessionDownloadTask {
                guard produceResumeDataWhenCancel else {return}
                task.cancelByProducingResumeData({ (data) -> Void in
                })
            } else {
                task.cancel()
            }
        }))
    }
    
    override public func execute() {
        assert(task.state == .Suspended, "Task was resumed by something other than \(self).")

        task.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions(), context: &URLSessionTaskOperationKVOContext)
        
        task.resume()
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
