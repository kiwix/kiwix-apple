/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file defines the error codes and convenience functions for interacting with Operation-related errors.
*/

import Foundation

public let OperationErrorDomain = "OperationErrors"

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

public extension NSError {
    convenience init(code: OperationErrorCode, userInfo: [NSObject: AnyObject]? = nil) {
        self.init(domain: OperationErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}

// This makes it easy to compare an `NSError.code` to an `OperationErrorCode`.
public func ==(lhs: Int, rhs: OperationErrorCode) -> Bool {
    return lhs == rhs.rawValue
}

public func ==(lhs: OperationErrorCode, rhs: Int) -> Bool {
    return lhs.rawValue == rhs
}
