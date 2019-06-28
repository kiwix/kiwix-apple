//
//  NetworkActivityIndicatorController.swift
//  Kiwix
//
//  Created by Chris Li on 2/2/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class NetworkActivityController {
    static let shared = NetworkActivityController()
    private init() {}
    
    private var taskIdentifiers = [String]() {
        didSet {
            OperationQueue.main.addOperation {
                UIApplication.shared.isNetworkActivityIndicatorVisible = self.taskIdentifiers.count > 0
            }
        }
    }
    
    func taskDidStart(identifier: String) {
        taskIdentifiers.append(identifier)
    }
    
    func taskDidFinish(identifier: String) {
        guard let index = taskIdentifiers.firstIndex(of: identifier) else {
            return
        }
        taskIdentifiers.remove(at: index)
    }
}
