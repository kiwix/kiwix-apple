//
//  Network.swift
//  Kiwix
//
//  Created by Chris Li on 8/25/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import Operations

// , NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate
class Network: NSObject, NSURLSessionDelegate, OperationQueueDelegate  {
    static let shared = Network()
    let queue = OperationQueue()
    
    private override init() {
        super.init()
        queue.delegate = self
    }
    
    lazy var session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.kiwix.www")
        configuration.allowsCellularAccess = false
        configuration.discretionary = false
        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation) {
        print(queue.operationCount)
    }
    
    func operationQueue(queue: OperationQueue, willFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {}
    
    func operationQueue(queue: OperationQueue, didFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {
        print(queue.operationCount)
    }
    
    func operationQueue(queue: OperationQueue, willProduceOperation operation: NSOperation) {}
}
