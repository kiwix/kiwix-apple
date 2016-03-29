/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to implement the OperationObserver protocol.
*/

import Foundation

/**
    The `BlockObserver` is a way to attach arbitrary blocks to significant events 
    in an `Operation`'s lifecycle.
*/
public struct BlockObserver: OperationObserver {
    // MARK: Properties
    
    private let startHandler: (Operation -> Void)?
    private let cancelHandler: (Operation -> Void)?
    private let produceHandler: ((Operation, NSOperation) -> Void)?
    private let finishHandler: ((Operation, [NSError]) -> Void)?
    
    public init(startHandler: (Operation -> Void)? = nil, cancelHandler: (Operation -> Void)? = nil, produceHandler: ((Operation, NSOperation) -> Void)? = nil, finishHandler: ((Operation, [NSError]) -> Void)? = nil) {
        self.startHandler = startHandler
        self.cancelHandler = cancelHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }
    
    // MARK: OperationObserver
    
    public func operationDidStart(operation: Operation) {
        startHandler?(operation)
    }
    
    public func operationDidCancel(operation: Operation) {
        cancelHandler?(operation)
    }
    
    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        produceHandler?(operation, newOperation)
    }
    
    public func operationDidFinish(operation: Operation, errors: [NSError]) {
        finishHandler?(operation, errors)
    }
}
