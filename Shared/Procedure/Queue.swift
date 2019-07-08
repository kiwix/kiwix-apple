//
//  Queue.swift
//  Kiwix
//
//  Created by Chris Li on 10/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//


class LibraryOperationQueue: OperationQueue {
    static let shared = LibraryOperationQueue()
    private(set) weak var lastLibraryRefreshOperation: LibraryRefreshOperation?
    
    override init() {
        super.init()
        maxConcurrentOperationCount = 1
    }
    
    override func addOperation(_ op: Operation) {
        if let operation = op as? LibraryRefreshOperation {
            lastLibraryRefreshOperation = operation
        }
        super.addOperation(op)
    }
}
