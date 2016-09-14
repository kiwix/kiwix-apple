//
//  GlobalOperationQueue.swift
//  Kiwix
//
//  Created by Chris Li on 5/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Operations

class GlobalOperationQueue: OperationQueue {
    static let sharedInstance = GlobalOperationQueue()
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
