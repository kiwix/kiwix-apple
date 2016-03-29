//
//  Capability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

import Foundation

public enum CapabilityErrorCode: Int {
    public static var domain = "CapabilityErrors"
    
    case NotDetermined
    case NotAvailable
    case Denied
}

public enum CapabilityStatus {
    /// The capability has not been requested yet
    case NotDetermined
    
    /// The capability has been requested and approved
    case Authorized
    
    /// The capability has been requested but was denied by the user
    case Denied
    
    /// The capability is not available (perhaps due to restrictions, or lack of support)
    case NotAvailable
    
    /// There was an error requesting the status of the capability
    case Error(NSError)
}

public protocol CapabilityType {
    static var name: String { get }
    
    /// Retrieve the status of the capability.
    /// This method is called from the main queue.
    func requestStatus(completion: CapabilityStatus -> Void)
    
    /// Request authorization for the capability.
    /// This method is called from the main queue, and only if the
    /// capability's status is "NotDetermined"
    func authorize(completion: CapabilityStatus -> Void)
}

/// A condition for verifying and/or requesting a certain capability
public struct Capability<C: CapabilityType>: OperationCondition {
    
    public static var name: String { return "Capability<\(C.name)>" }
    public static var isMutuallyExclusive: Bool { return true }
    
    private let capability: C
    private let shouldRequest: Bool
    
    public init(_ capability: C, requestIfNecessary: Bool = true) {
        self.capability = capability
        self.shouldRequest = requestIfNecessary
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        guard shouldRequest == true else { return nil }
        return AuthorizeCapability(capability: capability)
    }
    
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            self.capability.requestStatus { status in
                if let error = status.error {
                    let conditionError = NSError(code: .ConditionFailed, userInfo: [
                        OperationConditionKey: self.dynamicType.name,
                        NSUnderlyingErrorKey: error
                    ])
                    completion(.Failed(conditionError))
                } else {
                    completion(.Satisfied)
                }
            }
        }
    }
}

private class AuthorizeCapability<C: CapabilityType>: Operation {
    private let capability: C
    
    init(capability: C) {
        self.capability = capability
        super.init()
        addCondition(AlertPresentation())
        addCondition(MutuallyExclusive<C>())
    }
    
    private override func execute() {
        dispatch_async(dispatch_get_main_queue()) {
            self.capability.requestStatus { status in
                switch status {
                    case .NotDetermined: self.requestAuthorization()
                    default: self.finishWithError(status.error)
                }
            }
        }
    }
    
    private func requestAuthorization() {
        dispatch_async(dispatch_get_main_queue()) {
            self.capability.authorize { status in
                self.finishWithError(status.error)
            }
        }
    }
}

private extension NSError {
    convenience init(capabilityErrorCode: CapabilityErrorCode) {
        self.init(domain: CapabilityErrorCode.domain, code: capabilityErrorCode.rawValue, userInfo: [:])
    }
}

private extension CapabilityStatus {
    private var error: NSError? {
        switch self {
            case .NotDetermined: return NSError(capabilityErrorCode: .NotDetermined)
            case .Authorized: return nil
            case .Denied: return NSError(capabilityErrorCode: .Denied)
            case .NotAvailable: return NSError(capabilityErrorCode: .NotAvailable)
            case .Error(let e): return e
        }
    }
}
