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
    
    private var tasks = [String]() {
        didSet {
            OperationQueue.main.addOperation {
                UIApplication.shared.isNetworkActivityIndicatorVisible = self.tasks.count > 0
            }
        }
    }
    
    func taskDidStart(identifier: String) {
        tasks.append(identifier)
    }
    
    func taskDidFinish(identifier: String) {
        guard let index = tasks.index(of: identifier) else {
            assert(false, "Network Indicator add/removal is not balanced")
        }
        tasks.remove(at: index)
    }
}
