//
//  URLSessionDownloadTaskOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import PSOperations

public class URLSessionDownloadTaskOperation: URLSessionTaskOperation {
    let task: NSURLSessionDownloadTask
    var produceResumeData: Bool
    
    public init(task: NSURLSessionDownloadTask, produceResumeData: Bool) {
        assert(task.state == .Suspended, "Tasks must be suspended.")
        self.task = task
        self.produceResumeData = produceResumeData
        super.init(task: task)
        
        addObserver(BlockObserver(cancelHandler: { _ in
            if produceResumeData {
                task.cancelByProducingResumeData({ (data) in
                })
            } else {
                task.cancel()
            }
        }))
    }
}
