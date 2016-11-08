//
//  GlobalQueue.swift
//  Kiwix
//
//  Created by Chris Li on 5/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import ProcedureKit

class GlobalQueue: ProcedureQueue {
    static let shared = GlobalQueue()
    
    // Fix: use specific class type
    fileprivate weak var scanOperation: Procedure?
    fileprivate weak var searchOperation: Procedure?
    fileprivate weak var articleLoadOperation: ArticleLoadOperation?
    
    func add(scan operation: Procedure) {
        addOperation(operation)
        scanOperation = operation
    }
    
    func add(search operation: Procedure) {
        if let scanOperation = scanOperation {
            operation.addDependency(scanOperation)
        }
        
        if let searchOperation = self.searchOperation {
            searchOperation.cancel()
        }
        addOperation(operation)
        searchOperation = operation
    }
    
    func add(load operation: ArticleLoadOperation) {
        if let scanOperation = scanOperation {
            operation.addDependency(scanOperation)
        }
        
        if let articleLoadOperation = self.articleLoadOperation {
            operation.addDependency(articleLoadOperation)
        }
        
        addOperation(operation)
        articleLoadOperation = operation
    }
}

public enum OperationErrorCode: Int {
    case conditionFailed = 1
    case executionFailed = 2
    
    // Error that should be reported to user
    case networkError
    case serverNameInvalid
    case authError
    case accessRevoked
    case unreachable
    case lackOfValue
    case unexpectedError
}
//
//extension OperationQueue {
//    // Oneday should be replaced with ExclusivityController
//    func getOperation(_ id: String) -> Operation? {
//        for operation in operations {
//            guard operation.name == id else {continue}
//            guard let operation = operation as? Operation else {continue}
//            return operation
//        }
//        return nil
//    }
//}
