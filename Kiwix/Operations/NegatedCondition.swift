/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The file shows how to make an OperationCondition that composes another OperationCondition.
*/

import Foundation

/**
    A simple condition that negates the evaluation of another condition.
    This is useful (for example) if you want to only execute an operation if the 
    network is NOT reachable.
*/
public struct NegatedCondition<T: OperationCondition>: OperationCondition {
    public static var name: String { 
        return "Not<\(T.name)>"
    }
    
    static var negatedConditionKey: String { 
        return "NegatedCondition"
    }
    
    public static var isMutuallyExclusive: Bool {
        return T.isMutuallyExclusive
    }
    
    let condition: T

    public init(condition: T) {
        self.condition = condition
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return condition.dependencyForOperation(operation)
    }
    
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        condition.evaluateForOperation(operation) { result in
            switch result {
            case .Failed(_):
                // If the composed condition failed, then this one succeeded.
                completion(.Satisfied)
            case .Satisfied:
                // If the composed condition succeeded, then this one failed.
                let error = NSError(code: .ConditionFailed, userInfo: [
                    OperationConditionKey: self.dynamicType.name,
                    self.dynamicType.negatedConditionKey: self.condition.dynamicType.name
                    ])
                
                completion(.Failed(error))
            }
        }
    }
}
