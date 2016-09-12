//
//  GlobalQueue.swift
//  Kiwix
//
//  Created by Chris Li on 5/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Operations

class GlobalQueue: OperationQueue {
    static let shared = GlobalQueue()
    
    private weak var scanOperation: ScanLocalBookOperation?
    private weak var searchOperation: SearchOperation?
    
    func add(scan operation: ScanLocalBookOperation) {
        addOperation(operation)
        scanOperation = operation
    }
    
    func add(search operation: SearchOperation) {
        if let _ = searchOperation {
            print("search is not released")
        }
        
        if let scanOperation = scanOperation {
            operation.addDependency(scanOperation)
            print("scan not finished")
        }
        
        if let searchOperation = self.searchOperation {
            searchOperation.cancel()
        }
        addOperation(operation)
        searchOperation = operation
    }
}

public enum OperationErrorCode: Int {
    case ConditionFailed = 1
    case ExecutionFailed = 2
    
    // Error that should be reported to user
    case NetworkError
    case ServerNameInvalid
    case AuthError
    case AccessRevoked
    case Unreachable
    case LackOfValue
    case UnexpectedError
}

extension OperationQueue {
    // Oneday should be replaced with ExclusivityController
    func getOperation(id: String) -> Operation? {
        for operation in operations {
            guard operation.name == id else {continue}
            guard let operation = operation as? Operation else {continue}
            return operation
        }
        return nil
    }
}
