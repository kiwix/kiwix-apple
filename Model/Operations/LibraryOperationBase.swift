//
//  LibraryOperationBase.swift
//  Kiwix
//
//  Created by Chris Li on 3/22/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

class LibraryOperationQueue: OperationQueue {
    static let shared = LibraryOperationQueue()
    private(set) weak var currentOPDSRefreshOperation: OPDSRefreshOperation?

    private override init() {
        super.init()
        maxConcurrentOperationCount = 1
    }

    override func addOperation(_ op: Operation) {
        if let operation = op as? OPDSRefreshOperation {
            currentOPDSRefreshOperation = operation
        }
        super.addOperation(op)
    }
}
